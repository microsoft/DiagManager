param(
  [string]$source_path,
  [string]$destination_path,
  [string]$file_name
)

 
$count = @(Get-ChildItem -Path $source_path -Filter $file_name).Count

If ($count -gt 0)
{
Copy-Item -Path $source_path -Destination $destination_path -Filter $file_name
}