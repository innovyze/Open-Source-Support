# NOAA CO-OPS API For Data Retrieval:
# https://api.tidesandcurrents.noaa.gov/api/prod/
# User defined variables
$DataPath = 'C:\TEMP\NOAA\'
# Parameters
$NoaaParams = @{
    Url = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"
    TMZ = 'GMT'                           # Timezone of incoming data
    Datum = 'MLLW'                        # Datum of incoming data
    Units = 'English'                     # Units system
}
$ObsParams = @{                           # Parameters for Observed data (example)
    Period = 72                           # Time range of data (h)
    Type = 'obs'                          # Type of data (observed / predicted)
    Product = 'water_level'               # Type of data
    Interval = '6'                        # Interval for which data is returned 
}
$ForParams = @{                           # Parameters for Forecast data (example)
    Period = 72                           # Time range of data (h)
    Type = 'prs'                          # Type of data (observed / predicted)
    Product = 'predictions'               # Type of data
    Interval = 'h'                        # Interval for which data is returned 
}
# Sites
# https://tidesandcurrents.noaa.gov/
$NoaaSites = @(                           # =< Add more sites as needed >=
    '8519483'                             # Bergen
    '8518750'                             # Battery
)
# Functions
# Generates a URL to download the data with origin rounded to the current hour
function Set-RestUrl {
    Param($Site, $Stream)
    $CurrentTime = (Get-Date).ToUniversalTime().ToString("yyyyMMdd HH:00")
    if ($Stream.Type -eq 'obs') { $StreamPeriod = "end_date={0}&range={1}" –f $CurrentTime, $Stream.Period }
    if ($Stream.Type -eq 'prs') { $StreamPeriod = "begin_date={0}&range={1}" –f $CurrentTime, $Stream.Period }
    $StringQuery = "{0}&station={1}&product={2}&datum={3}&time_zone={4}&interval={5}&units={6}&application=web_services&format=json" `
        –f $StreamPeriod, $Site, $Stream.Product, $NoaaParams.Datum, $NoaaParams.TMZ, $Stream.Interval, $NoaaParams.Units
    $NoaaParams.Url + '?' + $StringQuery
}
# Gets the data and converts it to Simple CSV tor TSDB consumption
function Get-Data {
    Param($Sites, $Stream, $Path)
    Foreach ($Site in $Sites) {
        $OutFile = ($Path + $Site + '_' + $Stream.Type + '_' +  $Stream.Period + "hrs.csv")
        $Url = Set-RestUrl -Site $Site -Stream $Stream
        $json = Invoke-WebRequest -Uri $Url -UseBasicParsing | ConvertFrom-Json
        if ($Stream.Type -eq 'obs') { $data = $json.data }
        if ($Stream.Type -eq 'prs') { $data = $json.predictions }
        $data | Select-Object t,v | ConvertTo-CSV -NoTypeInformation |
        Select-Object -Skip 1 | ForEach-Object {$_ -replace '"',''} |
        Out-File -encoding "ASCII" $OutFile
    }
}
# Create a path for the files if it doesn't exist
New-Item -ItemType Directory -Force -Path $DataPath | Out-Null
# Call Get-Data function
Get-Data -Sites $NoaaSites -Stream $ObsParams -Path $DataPath
Get-Data -Sites $NoaaSites -Stream $ForParams -Path $DataPath