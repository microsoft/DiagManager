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
Write-Output "*************************************************"


#build a ""server_instance"" string from "server\instance" string
$server_instance = $Server -replace "\\", "_"

# Copying ERRORLOG files
$ErrlogFiles = Get-ChildItem -File -Path $vLogPath -Filter "ERRORLOG*" 

foreach ($file in $ErrlogFiles)
{
   $source = $file.FullName
   $destination = $DestinationFolder + $server_instance + "_" + $file.Name
   $destination_head_tail = $DestinationFolder + $server_instance + "_" + $file.Name + "_Head_and_Tail_Only"

   if ($file.Length -ge 1073741824)
   {
     Write-Output $destination_head_tail
     Get-Content $source -TotalCount 500 | Set-Content -Path $destination_head_tail | Out-Null
     Add-Content -Value "`n   <<... middle part of file not captured because the file is too large (>1 GB) ...>>`n" -Path $destination_head_tail | Out-Null
     Get-Content $source -Tail 500 | Add-Content -Path $destination_head_tail | Out-Null
   }
   elseif ($file.Length -gt 0)
   {
     Write-Output $destination
     Copy-Item -Path $source -Destination  $destination | Out-Null
   }
}

Write-Output "*************************************************"

# Copying SQLAGENT files
$SQLAgentlogFiles = Get-ChildItem -File -Path $vLogPath -Filter "SQLAGENT*" 


foreach ($file in $SQLAgentlogFiles)
{
   $source = $file.FullName
   $destination = $DestinationFolder + $server_instance + "_" + $file.Name

   Copy-Item -Path  $source  -Destination  $destination  | Out-Null
   Write-Output $destination
}

Write-Output "*************************************************"