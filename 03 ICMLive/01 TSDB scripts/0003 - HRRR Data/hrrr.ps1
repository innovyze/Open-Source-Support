#-----------------------------------------------------------
# Run the script at an interval of 15 min
# Created by Nathan.Gerdts@Innovyze.com
# Last edited Dec 3, 2020 by daniel.moreira@innovyze.com
# Last edited July 18, 2021 by mel.meng@innovyze.com
# Download the 18 HRRR forecast files. Once all the files are downloaded
# ICMLive will load all the files and move them into the loaded folder
# The challenge is that some times it takes more than 30 min to have all
# the files ready for download. So we need to run the download script
# a few times to make sure all the files are downloade.
# And once all the files are downloaded and moved into the "loaded" folder,
# we need a way to tell the script to stop downloading them
#-----------------------------------------------------------

# Set the execution policy for the current PowerShell session
# Mel-had to remvoe this line otherwise it ignores all the errors
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

#-----------------------------------------------------------
# Input parameters
#-----------------------------------------------------------
Param(
    [Parameter(Mandatory=$true)]
    [decimal]$Lon_min,
    [Parameter(Mandatory=$true)]
    [decimal]$Lon_max,
    [Parameter(Mandatory=$true)]
    [decimal]$Lat_min,
    [Parameter(Mandatory=$true)]
    [decimal]$Lat_max,
    [Parameter(Mandatory=$true)]
    [string]$Local_Path, 
    # Optional input, if entered will be treated as the same time zone as the system. Consistent with how $now is the system time zone.
    [string]$datetime 
)

# write-output "input parameters:"
# Write-output "$Lon_min, $Lon_ma, $Lat_min, $lat_max, $Local_path, $datetime"


#-----------------------------------------------------------
# Adding Logging feature
#-----------------------------------------------------------
$logfilepath = "$Local_Path\hrrr.log" # hard code the log file name
function WriteToLogFile ($level, $message)
{
   $now = Get-Date
    Add-content $logfilepath -value "[$level $(Get-Date $now.ToUniversalTime() -format 'yyyy-MM-ddTHH:mm')(UTC)]$message"
}

WriteToLogFile "INFO" '---------------------START-----------------------------------'
WriteToLogFile "INFO" '$Lon_min, $Lon_ma, $Lat_min, $lat_max, $Local_path, $datetime'
WriteToLogFile "INFO"  "$Lon_min, $Lon_ma, $Lat_min, $lat_max, $Local_path, $datetime"


#-----------------------------------------------------------
# Get current UTC hour in string format
#-----------------------------------------------------------
If ($PSBoundParameters.ContainsKey('datetime'))
    {$now = [DateTime]::parseexact($datetime, 'yyyy-MM-dd HH:mm', $null)}
else
    {# minus 1 since files are 50-80 minutes late
        $now = [DateTime]::Now.AddHours(-1)}

$Hour = Get-Date $now.ToUniversalTime() -format HH
$today  = Get-Date $now.ToUniversalTime() -format yyyMMdd
[string]$Hr_Char = "{0:D2}" -f ($Hour)  # This bit converts hour to 2 character string with zero in front if needed

#-----------------------------------------------------------
# Prepare the download url
#-----------------------------------------------------------
$str1 = "https://nomads.ncep.noaa.gov/cgi-bin/filter_hrrr_sub.pl?file=hrrr.t"
$str2 = "z.wrfsubhf"
$str3 = ".grib2&var_PRATE=on&subregion=&leftlon="+$Lon_min+"&rightlon="+$Lon_max+`
    "&toplat="+$Lat_max+"&bottomlat="+$Lat_min+"&dir=%2Fhrrr."+$today+"%2Fconus"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# check if all the files are downloaded	
# if so, a file with the origin time should already be created.
$check_file = $Local_Path + "HRRR_"+$today+"_"+$HR_char+".txt"
$flag = "complete"
if (Test-Path -Path $check_file)
{
	# write-output "completed, exit"
    WriteToLogFile "INFO" 'All forecast files downloaded'
    WriteToLogFile "INFO" '---------------------END-----------------------------------'
	exit
} 

#-----------------------------------------------------------
# download the 18 files, Loop for each forecast hour
#-----------------------------------------------------------
For ($i=1; $i -le 18; $i++) {
    if($i-lt10){$fhr="0"+$i}else{[string]$fhr=$i}
    $url = $str1+$HR_char+$str2+$fhr+$str3
    $output = $Local_Path + "HRRR_"+$today+"_"+$HR_char+"_"+$fhr+"_.grib"
	if (-not (Test-Path -Path $output))
	{
		# write-output $url
		# write-output $output
        try {
            Invoke-WebRequest $url -WebSession $session -TimeoutSec 900 -OutFile $output    
        }
        catch [Exception] {
            WriteToLogFile "WARN", $_.Exception | format-list -force
        }
		
        # write-output "$url -> $output"
        WriteToLogFile "INFO" "$url -> $output"
		
	}
    }



# check if all the files are downloaded
For ($i=1; $i -le 18; $i++) {
    if($i-lt10){$fhr="0"+$i}else{[string]$fhr=$i}
    $url = $str1+$HR_char+$str2+$fhr+$str3
    $output = $Local_Path + "HRRR_"+$today+"_"+$HR_char+"_"+$fhr+"_.grib"
	if (-not (Test-Path -Path $output))

	{
		$flag = 'incomplete'
		# write-output "file not found: $output"
        WriteToLogFile "INFO" "file not found: $output"
	}
}

# if all the files are downloaded, save a check file
if ($flag -eq 'complete')
{
	New-Item -Path $check_file -ItemType "file"
	# write-output "download completed"
    WriteToLogFile "INFO" "download completed"

	
}

WriteToLogFile "INFO" '---------------------END-----------------------------------'