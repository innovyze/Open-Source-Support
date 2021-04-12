# USGS Instantaneous Values Web Service
# https://waterservices.usgs.gov/rest/IV-Service.html
$UsgsUrl = "https://waterservices.usgs.gov"
# User defined variables
$DataPath = "C:\TEMP\USGS\"
$LevlObsPeriod = 72                         # Period in h for observed level data to be retrieved
$RainObsPeriod = 72                         # Period in h for observed rainfall data to be retrieved
# Sites
# https://maps.waterdata.usgs.gov/mapper/index.html
$USGSTidlSites = @(                         # =< Add/Remove as necessary >=
  "01392650"                                # Newark
  "01376562"                                # Great Kills Harbor
)
$USGSLevlSites = @(                         # =< Add/Remove as necessary >=
  "01389890"                                # Dundee Dam
  "01391500"                                # Saddle River at Lodi
)
$USGSRainSites = @(                         # =< Add/Remove as necessary >=
  "405245074022401"                         # Hackensack
  "405934074120201"                         # Ridgewood
)
# Parameter codes
# https://help.waterdata.usgs.gov/codes-and-parameters/parameters
$ParamCodes = @{                            # =< Add as necessary >=
  TidElevation = '72279'
  PhysGageHeight = '00065'
  PhysPrecip = '00045'
}
# Function to get data in JSON format, convert date time to UTC and export relevant fields to TSDB "Simple CSV" format
function Get-Data {
  Param($SiteArray, $ParameterCd, $Period)
  ForEach ($SiteId in $SiteArray) {
    $OutFile = ($DataPath + $SiteId + "_obs_" + $Period + "hrs.csv")
    $RestUrl = $UsgsUrl + "/nwis/iv/?sites=" + $SiteId +"&format=json&period=PT" + $Period + "H&parameterCd=$parameterCd"
    $json = Invoke-WebRequest -Uri $RestUrl -UseBasicParsing | ConvertFrom-Json
    $json.value.timeseries.values.value | Select-Object datetime,value |
    ForEach-Object { 
      $_.datetime = [datetime]::Parse($_.datetime).ToUniversalTime().ToString("yyyy-MM-dd HH:mm")
      $_
    } |
    ConvertTo-CSV -NoTypeInformation |
    ForEach-Object {$_ -replace '"',''} |
    Select-Object -Skip 1 |
    Out-File -encoding "ASCII" $OutFile
    Write-Output $OutFile
  }
}
# Create a path for the files if it doesn't exist
New-Item -ItemType Directory -Force -Path $DataPath | Out-Null
# Call Get-Data function
Get-Data -SiteArray $USGSTidlSites -ParameterCd $ParamCodes.TidElevation -Period $LevlObsPeriod
Get-Data -SiteArray $USGSLevlSites -ParameterCd $ParamCodes.PhysGageHeight -Period $LevlObsPeriod
Get-Data -SiteArray $USGSRainSites -ParameterCd $ParamCodes.PhysPrecip -Period $RainObsPeriod
# Example REST Url
# https://waterservices.usgs.gov/nwis/iv/?sites=405939074084301&format=rdb&period=PT72H&parameterCd=00045