# run example
# powershell.exe -ExecutionPolicy Bypass   .\SqlBaseUtil.ps1 GetWindowsHotfix
param(
  [string]$argument,
  [string]$output_path
)
   
try 
{
    

    #filter drivers
    $executable = "fltmc.exe"
    #throw 'abc'
    Write-Host $output_path

    if (($argument -eq "filters") -or ($argument -eq "instances"))
    {
        Start-Process -FilePath $executable -ArgumentList $argument -WindowStyle Normal -RedirectStandardOutput $output_path
    }

}
catch {
    Write-Host $_.ErrorID 
    Write-Host $_.Exception.Message
    return
}

Write-Output $ComputerName;