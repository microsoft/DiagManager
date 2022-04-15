#Generates a list of currently running processes, service information and tasks with DLL modules loaded on the local machine and saves to file
Write-Output "Current time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
Write-Output "`nGenerating running processes task list..."
Write-Output "`n-- task_list --" 
(TASKLIST /V /FO TABLE) -replace "=", "-" | Where-Object {$_.trim() -ne ""} 

Write-Output "`nGenerating running service list..."
Write-Output "`n-- service_list --" 
(TASKLIST /SVC /FO TABLE) -replace "=", "-" | Where-Object {$_.trim() -ne ""} 

Write-Output "`nGenerating DLL modules loaded task list..."
Write-Output "`n-- module_list --" 
(TASKLIST /M /FO TABLE) -replace "=", "-" | Where-Object {$_.trim() -ne ""} 
