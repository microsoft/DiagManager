# Copy the SQL ERRORLOG and SQL AGENT files to the destination output folder

param
(
  [Parameter(Position=0)]
  [string] $DestinationFolder,
  [Parameter(Position=1)]
  [string] $Server
)

function Get-InstanceNameOnly([string]$NetnamePlusInstance)
{
    try 
    {
        $selectedSqlInstance = $NetnamePlusInstance.Substring($NetnamePlusInstance.IndexOf("\") + 1)
        return $selectedSqlInstance         
    }
    catch 
    {
        Write-Output "Exception in Get-InstanceNameOnly: $_.Exception.Message)"
    }
}

if ($Server -notlike '*\*')
{
  $vInstance = "MSSQLSERVER"
} 
 else
{
  $vInstance = Get-InstanceNameOnly -NetnamePlusInstance $Server 
}

Write-Output "Fetch the SQLERRORLOG and SQL AGENT files and copy them to the destination folder"
Write-Output "Server: $Server"
Write-Output "Destination folder: $DestinationFolder"

$vRegInst = (Get-ItemProperty -Path HKLM:"SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL").$vInstance
$vRegPath = "SOFTWARE\Microsoft\Microsoft SQL Server\" + $vRegInst + "\MSSQLServer\Parameters" 
$vLogPath = (Get-ItemProperty -Path HKLM:$vRegPath).SQLArg1 -replace '-e'
$vLogPath = $vLogPath -replace 'ERRORLOG'

Write-Output "The \LOG folder discovered is: $vLogPath"

# Copying ERRORLOG files
Get-ChildItem -File -Path $vLogPath -Filter "ERRORLOG*" | Copy-Item -Destination $DestinationFolder | Out-Null

# Copying SQLAGENT files
Get-ChildItem -File -Path $vLogPath -Filter "SQLAGENT*" | Copy-Item -Destination $DestinationFolder | Out-Null