# run example
# powershell.exe -ExecutionPolicy Bypass   .\SqlBaseUtil.ps1 GetWindowsHotfix
param(
  [string]$InvokeMethod,
  [string]$OutputPath
)

function Replicate ([string] $char, [int] $cnt)
{
    $finalstring = $char * $cnt;
    return $finalstring;
}


function PadString (  [string] $arg1,  [int] $arg2 )
{
     $spaces = Replicate " " 256
     $retstring = "";
    if (!$arg1 )
    {
        $retstring = $spaces.Substring(0, $arg2);
     }
    elseif ($arg1.Length -eq  $arg2)
    {
        $retstring= $arg1;
       }
    elseif ($arg1.Length -gt  $arg2)
    {
        $retstring = $arg1.Substring(0, $arg2); 
        
    }
    elseif ($arg1.Length -lt $arg2)
    {
        $retstring = $arg1 + $spaces.Substring(0, ($arg2-$arg1.Length));
    }
    return $retstring;
}

function GetWindowsHotfix
{
$hotfixes = Get-WmiObject -Class "win32_quickfixengineering"
$Identifier = "-- Windows Hotfix List --";
$Header1 = PadString "HotfixID" 15;
$header1 += PadString "InstalledOn" 15;
$header1 += PadString "Description" 30;
$header1 += PadString "InstalledBy" 30;
$header2 = Replicate "-" 14
$header2 += " ";
$header2 += Replicate "-" 14;
$header2 += " ";
$header2 += Replicate "-" 29;
$header2 += " ";
$header2 +=Replicate "-" 29;
$header2 += " ";
Write-Output $Identifier;
Write-Output $header1;
Write-Output $header2;
foreach ($hf in $hotfixes)
{
   
  $hotfixid =  $hf["HotfixID"] + "";
  $installedOn = $hf["InstalledOn"] + "";
  $Description = $hf["Description"] + "";
  $InstalledBy = $hf["InstalledBy"] + "";
  $output = PadString  $hotfixid 15
  $output +=  PadString $installedOn  15;
  $output +=  PadString $Description 30;
  $output += PadString $InstalledBy  30;
    Write-Output $output 
}

$Blankstring =   Replicate " " 50;
Write-Output $Blankstring;
}


function GetEventLogs()
{
	$servers ="."
	$date = ( get-date ).ToString('yyyyMMdd');
	$file = New-Item -type file "c:\temp\test1.txt" -Force;
	Get-EventLog -log Application -Computer $servers   -newest 3000  |Format-Table -Property *  -AutoSize |Out-String -Width 20000  |out-file $file
}

# main function 
if ($InvokeMethod -eq "GetWindowsHotfix")
{
    GetWindowsHotfix
}


Write-Output $ComputerName;