
param
(
    [Parameter(ParameterSetName = 'ServiceRelated',Mandatory=$true)]
    [Parameter(Position = 0)]
    [string] $ServiceState = "",

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [switch] $help,

    [Parameter(ParameterSetName = 'Config',HelpMessage='/I xml_config_file',Mandatory=$false)]
    [string] $I = "pssdiag.xml",

    [Parameter(ParameterSetName = 'Config',HelpMessage='/O output_path',Mandatory=$false)]
    [string] $O = "output",

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [string] $P = "",

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [string] $N = "1",

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [string] $M = [string]::Empty,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [switch] $Q ,
    
    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [string] $C = "0",

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [switch] $G,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [switch] $R,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [switch] $U,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [string] $A = [string]::Empty,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [switch] $L,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [switch] $X,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [string] $B = [string]::Empty,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [string] $E = [string]::Empty,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [string] $T = [string]::Empty,

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [switch] $DebugOn


)


. ./Confirm-FileAttributes.ps1


function Check-ElevatedAccess
{
    try 
    {
	
        #check for administrator rights
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
        {
            Write-Warning "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") Elevated privilege (run as Admininstrator) is required to run PSSDIAG. Exiting..."
            exit
        }
        
    }

    catch 
    {
        Write-Error "Error occured in $($MyInvocation.MyCommand), $($PSItem.Exception.Message ), line number: $($PSItem.InvocationInfo.ScriptLineNumber)" 
		exit
    }
    

}


function FindSQLDiag ()
{

    try
    {
				
        [bool]$is64bit = $false

        [xml]$xmlDocument = Get-Content -Path .\pssdiag.xml
        [string]$sqlver = $xmlDocument.dsConfig.Collection.Machines.Machine.Instances.Instance.ssver
		
		#first find out if their registry is messed up
		ValidateCurrentVersion -ssver $sqlver

		[string[]] $valid_versions = "10", "10.50", "11", "12", "13", "14", "15", "16"

		while ($sqlver -notin $valid_versions)
		{
			Write-Warning "An invalid version is specified for SQL Server (ssver = '$sqlver') in the pssdiag.xml file. This prevents selecting correct SQLDiag.exe path."
			$sqlver = Read-Host "Please enter the 2-digit version of your SQL Server ($valid_versions) to help locate SQLDiag.exe"

		}

        if ($sqlver -eq "10.50")
        {
              $sqlver = "10"
        }

        [string]$plat = $xmlDocument.dsConfig.DiagMgrInfo.IntendedPlatform


        [string] $x86Env = [Environment]::GetEnvironmentVariable( "CommonProgramFiles(x86)");


         #[System.Environment]::Is64BitOperatingSystem

        if ($x86Env -ne $null)
        {
            $is64bit = $true
        }

        $toolsRegStr = ("HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $sqlver+"0\Tools\ClientSetup")
		
	
	
        # for higher versions of PS use: [string]$toolsBinFolder = Get-ItemPropertyValue -Path $toolsRegStr -Name Path
        [string]$toolsBinFolder = (Get-ItemProperty -Path $toolsRegStr -Name Path).Path


		#strip "(x86)" in case Powershell goes to HKLM\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\ under the covers, which it does
		
		$toolsBinFolderx64 = $toolsBinFolder.Replace("Program Files (x86)", "Program Files")

		
		$sqldiagPath = ($toolsBinFolder + "sqldiag.exe")
        $sqldiagPathx64 = ($toolsBinFolderx64 + "sqldiag.exe")
		
		
	
        if ((Test-Path -Path $sqldiagPathx64))
        {
			return $sqldiagPathx64
		}
		
		else
		{
			#path was not valid so checking second path
			
			if ($sqldiagPath -ne $sqldiagPathx64)
			{
				if ((Test-Path -Path $sqldiagPath))
				{
					return $sqldiagPath
				}
			}
			
			Write-Host "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") Unable to find 'sqldiag.exe' version: $($sqlver)0 on this machine.  Data collection will fail"
			return "Path_Error_"
        }
        
		
    }
    catch 
    {
        Write-Error "Error occured in finding SQLDiag.exe: $($PSItem.Exception.Message)  line number: $($PSItem.InvocationInfo.ScriptLineNumber)" 
		return "Path_Error_"
    }

}

function ValidateCurrentVersion ([string]$ssver)
{
	[string[]] $intermediateNames = @()
	[string[]] $currentVersionReg = @()

	$regInstNames = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" 
	
	$instNames = Get-Item $regInstNames | Select-Object -ExpandProperty Property 

	# add the discovered values in an array
	foreach ($inst in $instNames)
	{
		# for higher versions of Powershell use: $intermediateNames+= ( Get-ItemPropertyValue -Path $regInstNames -Name $inst)
        $intermediateNames+= ( Get-ItemProperty -Path $regInstNames -Name $inst).$inst
	}


	[int] $nonMatchCounter = 0

	foreach($name in $intermediateNames)
	{

		$regRoot = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" + $name + "\MSSQLServer\CurrentVersion"
		
        # for higher versions of PS use: $verString = Get-ItemPropertyValue -Path $regRoot -Name CurrentVersion
        $verString = (Get-ItemProperty -Path $regRoot -Name CurrentVersion).CurrentVersion

		$currentVersionReg+= ($regRoot + "=>" + $verString)

		# get the major version value from the reg entry
		$majVersion = $verString.Substring(0, $verString.IndexOf("."))

        # for version 2008R2 number is 10.50 and we had to remove .50
        #IndexOf function returns -1 for SQLs without minor version number (only 2008R2 has this number, which is 50. All others are zero). 

        if ($ssver.IndexOf(".") -eq -1) 
        {
            $tempssver =  $ssver

        }
        else 
        {
            $tempssver = $ssver.Substring(0, $ssver.IndexOf("."))
        }



        if ($majVersion -ne $tempssver)
		{
			$nonMatchCounter++
		}

	}

    if ($nonMatchCounter -eq $intermediateNames.Count)
	{
		Write-Warning "Collection may fail. No instance was found for the version of SQL Server configured in pssdiag.xml (ssver='$ssver')."
        Write-Warning "Examine these reg keys to see if the one or more versions is different from expected version $ssver (first 2 digits in NN.n.nnnn):`n"
        foreach ($entry in $currentVersionReg)
		{
			Write-Warning $entry 
		}
	}

}



function PrintHelp
{
	 Write-Host " [-I cfgfile] = sets the configuration file, typically either pssdiag.xml or sqldiag.xml.`n"`
        "[-O outputpath] = sets the output folder.  Defaults to startupfolder\SQLDIAG (if the folder does not exist, the collector will attempt to create it) `n" `
        "[-N #] = output folder management at startup #: 1 = overwrite (default), 2 = rename (format is OUTPUT_00001,...00002, etc.) `n" `
        "[-P supportpath] = sets the support path folder.  Defaults to startupfolder if not specified `n" `
        "[-M machine1 [machine2 machineN]|`@machinelistfile] = overrides the machines specified in the config file. When specifying more than one machine, separate each machine name with a space. "`@" specifies a machine list file `n" `
        "[-Q]  = quiet mode -- supresses prompts (e.g., password prompts) `n" `
        "[-C #] = file compression type: 0 = none (default), 1 = NTFS, 2 = CAB `n" `
        "[-G]  = generic mode -- SQL Server connectivity checks are not enforced; machine enumeration includes all servers, not just SQL Servers `n" `
        "[-R]  = registers the collector as a service `n" `
        "[-U]  = unregisters the collector as a service `n" `
        "[-A appname] = sets the application name.  If running as a service, this sets the service name `n" `
        "[-L] = continuous mode -- automatically restarts when shutdown via -X or -E `n" `
        "[-X] = snapshot mode -- takes a snapshot of all configured diagnostics and shuts down immediately `n" `
        "[-B [+]YYYYMMDD_HH:MM:SS] = specifies the date/time to begin collecting data; "+HH:MM:SS" specifies a relative time `n" `
        "[-E [+]YYYYMMDD_HH:MM:SS]  = specifies the date/time to end data collection; "+HH:MM:SS" specifies a relative time `n" `
        "[-T {tcp[,port]|np|lpc|via}] = connects to sql server using the specified protocol `n" `
        "[-Debug] = print some verbose messages for debugging where appropriate `n" `
        "[START], [STOP], [STOP_ABORT] = service commands for a registered (-R) SQLDIAG service `n" `
        ""        -ForegroundColor Green

        exit
}

function main 
{

    [bool] $debug_on = $false

    if ($DebugOn -eq $true)
    {
        $debug_on = $true
    }
	
	if (Check-ElevatedAccess -eq $true)
	{
		exit
	}
	

    $validFileAttributes = Confirm-FileAttributes $debug_on
        if (-not($validFileAttributes)){
            Write-Host "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") File attribute validation FAILED. Exiting..." -ForegroundColor Red
            return
        }
        
    
    [string[]] $argument_array = @()

    if ($ServiceState -iin "stop", "start", "stop_abort")
    {
        Write-Host "ServiceState = $ServiceState"
        $argument_array += $ServiceState   
    }
    elseif (($ServiceState -iin "--?", "/?", "?", "--help", "help") -or ($help -eq $true) )
    {
        PrintHelp
    }
    else
    {
        
        # [/I cfgfile] = sets the configuration file, typically either sqldiag.ini or sqldiag.xml.  Default is sqldiag.xml
        $lv_I = "/I" + $I

        # [/O outputpath] = sets the output folder.  Defaults to startupfolder\SQLDIAG (if the folder does not exist, the collector will attempt to create it)
        #if this is a full directory path make sure to trim a final backslash because SQLDiag would fail to start the service if that exists
        if ($O.Substring($O.Length -1) -eq "`\")
        {
          $O = $O.Substring(0,$O.Length -1)
        }

        $lv_O = "/O" + $O

        
        # [/P supportpath] = sets the support path folder.   By default, /P is set to the folder where the SQLdiag executable resides. 
		# The support folder contains SQLdiag support files, such as the XML configuration file, Transact-SQL scripts, and other files that the utility uses during diagnostics collection. 
		# If you use this option to specify an alternate support files path, SQLdiag will automatically copy the support files it requires to the specified folder if they do not already exist.
        $pwd = Get-Location
        
        if ([string]::IsNullOrWhiteSpace($P) -eq $false) 
        {
          #trim a final backslash because SQLDiag would fail to start the service if that exists
          if ($P.Substring($P.Length -1) -eq "`\")
          {
            $P = $P.Substring(0,$P.Length -1)
          }

          $lv_P = "/P" + $P 
        }

        else
        {
            $lv_P = "/P" + $pwd.Path
        }
        


        # [/N #] = output folder management at startup #: 1 = overwrite (default), 2 = rename (format is OUTPUT_00001,...00002, etc.)
        $lv_N = "/N" + $N

        # [/M machine1 [machine2 machineN]|@machinelistfile] = overrides the machines specified in the config file. When specifying more than one machine, separate each machine name with a space. "@" specifies a machine list file
        if ([string]::IsNullOrWhiteSpace($M))
        {
            $lv_M = ""
        }
        else 
        {
            $lv_M = "/M" + $M    
        }


        # [/Q]  = quiet mode -- supresses prompts (e.g., password prompts)

        if ($Q -eq $false)
        {
            $lv_Q = ""
        }
        else 
        {
            $lv_Q = "/Q"
        }
        
        # [/C #] = file compression type: 0 = none (default), 1 = NTFS, 2 = CAB

        $lv_C = "/C" + $C
        
        # [/G]  = generic mode -- SQL Server connectivity checks are not enforced; machine enumeration includes all servers, not just SQL Servers
        
        if ($G -eq $false)
        {
            $lv_G = ""
        }
        else 
        {
            $lv_G = "/G"
        }
        
        # [/R]  = registers the collector as a service

        if ($R -eq $false)
        {
            $lv_R = ""
        }
        else 
        {
            $lv_R = "/R"
        }
        
        # [/U]  = unregisters the collector as a service
        
        if ($U -eq $false)
        {
            $lv_U = ""
        }
        else 
        {
            $lv_U = "/U"
        }

        # [/A appname] = sets the application name to DIAG$appname.  If running as a service, this sets the service name to DIAG$appname

        if ([string]::IsNullOrWhiteSpace($A))
        {
            $lv_A = ""
        }
        else 
        {
            $lv_A = "/A" + $A
        }

        # [/L] = continuous mode -- automatically restarts when shutdown via /X or /E
        
        if ($L -eq $false)
        {
            $lv_L = ""
        }
        else 
        {
            $lv_L = "/L"
        }

        
        # [/X] = snapshot mode -- takes a snapshot of all configured diagnostics and shuts down immediately

        if ($X -eq $false)
        {
            $lv_X = ""
        }
        else 
        {
            $lv_X = "/X"
        }

        
        # [/B [+]YYYYMMDD_HH:MM:SS] = specifies the date/time to begin collecting data; "+" specifies a relative time

        if ([string]::IsNullOrWhiteSpace($B))
        {
            $lv_B = ""
        }
        else 
        {
            $lv_B = "/B" + $B
        }
        
        # [/E [+]YYYYMMDD_HH:MM:SS]  = specifies the date/time to end data collection; "+" specifies a relative time
        
        if ([string]::IsNullOrWhiteSpace($E))
        {
            $lv_E = ""
        }
        else 
        {
            $lv_E = "/E" + $E
        }

        # [/T {tcp[,port]|np|lpc|via}] = connects to sql server using the specified protocol

        if ([string]::IsNullOrWhiteSpace($T))
        {
            $lv_T = ""
        }
        else 
        {
            $lv_T = "/T" + $T
        }    
        
        [string[]] $argument_arrayTemp = @()  
		
        if ($lv_U -eq "/U")
        {
            $argument_arrayTemp = $lv_A, $lv_U
        }
        else 
        {
            # special case if user typed /r instead of -R
            if ($ServiceState -eq "/r")
            {
                $lv_R = "/R"
            }
            
            $argument_arrayTemp = $lv_I, $lv_O, $lv_P, $lv_N, $lv_M, $lv_Q, $lv_C, $lv_G, $lv_R, $lv_A, $lv_L, $lv_X, $lv_B, $lv_E, $lv_T
        }
        
        foreach ($item in $argument_arrayTemp)
        {
            if (($item.Trim()) -ne "")
            {
                $argument_array += $item.Trim()
            }		
        }
        
    }

	# locate the SQLDiag.exe path for this version of PSSDIAG
	[string]$sqldiag_path = FindSQLDiag
	
	if ("Path_Error_" -eq $sqldiag_path)
	{
		#no valid path found to run SQLDiag.exe, so exiting
		exit
	}

		

	#Translate Performance Counters if((Get-WinSystemLocale).name -notlike "en*")
    & .\perfmon_translate.ps1

    # launch the sqldiag.exe process and print the last 5 lines of the console file in case there were errors

    Write-Host "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") Executing: $sqldiag_path $argument_array"
    Write-Host "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") Number of parameters passed: $($argument_array.Length)"
    & $sqldiag_path $argument_array

    
    $console_log = ".\output\internal\##console.log"

    if (($R -eq $true) -or ($ServiceState -in "stop", "start", "stop_abort") -or ($U -eq $true))
    {
        if($R -eq $true)
        {
            Write-Host "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") Registered SQLDiag as a service. Please make sure you run 'pssdiag.ps1 START' or 'SQLDIAG START' or 'net start SQLDIAG'" -ForegroundColor Green
        }

        if($U -eq $true)
        {
            Write-Host "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") Un-registered SQLDiag as a service." -ForegroundColor Green
        }
        
    }
    elseif (Test-Path -Path $console_log )
    {
        Write-Warning "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") Displaying the last 5 lines from \output\internal\##console.log file. If SQLDiag did not run for some reason, you may be reading an old log."
	    Get-Content -Tail 5 $console_log 
        Write-Host "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff") SQLDiag has completed. You can close the window. If you got errors, please review \output\internal\##SQLDIAG.LOG file"
    }

	

}


main
