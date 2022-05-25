#Generate systeminfo report and save to file 
Write-Output "Start time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" 
Write-Output "`nGenerating systeminfo report..."
Write-Output "`n-- system_info --" 
Write-Output "Property                   Value         " 
Write-Output "-------------------------- ----------------------------------------------------------------------------------------------------"
systeminfo.exe /FO LIST | Where-Object {$_.trim() -ne ""}
