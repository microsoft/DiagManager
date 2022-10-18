param(
  [string]$argument,
  [string]$output_path
)
   
#filter drivers
$executable = "fltmc.exe"

if (($argument -eq "filters") -or ($argument -eq "instances"))
{
    Start-Process -FilePath $executable -ArgumentList $argument -WindowStyle Hidden -RedirectStandardOutput $output_path -Wait
    $tasklist = (Get-Content -Path $output_path) -replace ("=", "-")| Where-Object {$_.trim() -ne ""} 
    #Makeit importable in SQL Nexus
    if ($argument -eq "filters") 
    { 
      $newline="`n-- fltmc_filters --" 
      Set-Content $output_path -value $newline,$tasklist
    }
    else 
    {
      $newline="`n-- fltmc_instances --"
      Set-Content $output_path -value $newline,$tasklist
    }
    
}

Write-Output $ComputerName;