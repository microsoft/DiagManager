param(
  [Parameter(Position=0)]
  [string]$sourcePath,
  [Parameter(Position=1)]
  [string]$destinationPath,
  [Parameter(Position=2)]
  [string]$serverName
)

if ($serverName -Like '*\*')
{
  $serverName = $serverName -replace"\\","_"
}

Get-ChildItem $sourcePath -FILE | ForEach-Object { 

		If ([String]::IsNullOrEmpty($serverName))
		{
			$newFileName = $_.Name
		}
		else
		{
			$newfileName = $serverName + "_" + $_.Name
		}

		$newfileName = Join-path $destinationPath $newfileName

	Try { 
				Copy-Item -Path $_.FullName -Destination $newFileName -ErrorAction Stop
		}		
	Catch {
				Write-Output $_.Exception.Message 
		}
	}
