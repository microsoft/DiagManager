#Generate systeminfo report and save to file 
$servername=$args[0]
$outputpath=$args[1]
$osversion = (Get-WmiObject Win32_OperatingSystem).Version
$outputfile = ($outputpath + $servername + "_SYSTEMINFO.TXT")

Write-Output "GET_SYSTEMINFO Server: $servername"  
Write-Output "GET_SYSTEMINFO Output Path: $outputpath"  
Write-Output "GET_SYSTEMINFO Detected OS: $osversion"
Write-Output "GET_SYSTEMINFO Output File: $outputfile"

Write-Output "Current time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"

Write-Output "Generating systeminfo report: systeminfo.exe /FO LIST > $outputfile"
systeminfo.exe /FO LIST > $outputfile
Write-Output "Report completed"

Write-Output "Current time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
