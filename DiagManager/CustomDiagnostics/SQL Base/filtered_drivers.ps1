param(
  [string]$argument,
  [string]$output_path
)
   
try 
{
    

    #filter drivers
    $executable = "fltmc.exe"
    
    if (($argument -eq "filters") -or ($argument -eq "instances"))
    {
        Start-Process -FilePath $executable -ArgumentList $argument -WindowStyle Hidden -RedirectStandardOutput $output_path
    }

}
catch {
    Write-Host $_.ErrorID 
    Write-Host $_.Exception.Message
    return
}

Write-Output $ComputerName;