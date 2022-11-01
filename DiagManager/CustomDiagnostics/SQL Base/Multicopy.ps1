param(
  [Parameter(Position=0)]
  [string]$sourcePath,
  [Parameter(Position=1)]
  [string]$destinationPath,
  [Parameter(Position=2)]
  [string]$serverName
)


Get-ChildItem $sourcePath -FILE | ForEach-Object { 
		$newfileName = $serverName + "_" + $_.Name
 
		$newfileName = Join-path $destinationPath $newfileName

	Try { 
				Copy-Item -Path $_.FullName -Destination $newFileName -ErrorAction Stop
		}		
	Catch {
				$_.Exception.Message | Out-File -FilePath "c:\temp\error.txt" -Append
		}
	}