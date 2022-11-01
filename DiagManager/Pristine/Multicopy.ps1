param(
  [Parameter(Position=0)]
  [string]$sourcePath,
  [Parameter(Position=1)]
  [string]$destinationPath,
  [Parameter(Position=2)]
  [string]$serverName
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

if ($serverName -notlike '*\*')
{
  Return $serverName
} 
 else
{
  $serverName = Get-InstanceNameOnly -NetnamePlusInstance $serverName 
}

$errorFile = "c:\temp\copyFileError.txt"
If (Test-Path $errorFile)
{
   Remove-Item $errorFile
}

Get-ChildItem $sourcePath -FILE | ForEach-Object { 
		$newfileName = $serverName + "_" + $_.Name
 
		$newfileName = Join-path $destinationPath $newfileName

	Try { 
				Copy-Item -Path $_.FullName -Destination $newFileName -ErrorAction Stop
		}		
	Catch {
				$_.Exception.Message | Out-File -FilePath $errorFile -Append
		}
	}
