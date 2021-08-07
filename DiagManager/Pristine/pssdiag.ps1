
param
(
    [Parameter(ParameterSetName = 'ServiceRelated',Mandatory=$true)]
    [Parameter(Position = 0)]
    [string] $ServiceState = "",


    [Parameter(ParameterSetName = 'Config',HelpMessage='/I xml_config_file',Mandatory=$false)]
    [string] $I = "pssdiag.xml",

    [Parameter(ParameterSetName = 'Config',HelpMessage='/O output_path',Mandatory=$false)]
    [string] $O = "output",

    [Parameter(ParameterSetName = 'Config',Mandatory=$false)]
    [string] $P =[string]::Empty,

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
    [string] $T = [string]::Empty
)


function main 
{
    Write-Host "ServiceState = $ServiceState"

    [string] $argument_list = ""

    if ($ServiceState -iin "stop", "start", "stop_abort", "/U")
    {
        $argument_list = $ServiceState    
    }
    elseif ($ServiceState -iin "--?", "/?", "?", "--help", "-help") 
    {
        Write-Host " Help is on the way...`n"`
        "More help `n" `
        "More help `n" `
        "More help `n" `
        "More help "        -ForegroundColor Green

        exit
    }
    else
    {
        
        # [/I cfgfile] = sets the configuration file, typically either sqldiag.ini or sqldiag.xml.  Default is sqldiag.xml
        $lv_I = "/I " + $I

        # [/O outputpath] = sets the output folder.  Defaults to startupfolder\SQLDIAG (if the folder does not exist, the collector will attempt to create it)
        $lv_O = "/O " + $O
        
        # [/P supportpath] = sets the support path folder.  Defaults to startupfolder if not specified
        if ([string]::IsNullOrWhiteSpace($P))
        {
            $lv_P = ""
        }
        else 
        {
            $lv_P = "/P " + $P    
        }

        # [/N #] = output folder management at startup #: 1 = overwrite (default), 2 = rename (format is OUTPUT_00001,...00002, etc.)
        $lv_N = "/N " + $N

        # [/M machine1 [machine2 machineN]|@machinelistfile] = overrides the machines specified in the config file. When specifying more than one machine, separate each machine name with a space. "@" specifies a machine list file
        if ([string]::IsNullOrWhiteSpace($M))
        {
            $lv_M = ""
        }
        else 
        {
            $lv_M = "/M " + $M    
        }


        # [/Q]  = quiet mode -- supresses prompts (e.g., password prompts)

        if ($Q -eq $false)
        {
            $lv_Q = ""
        }
        else 
        {
            $lv_Q = "/Q "
        }
        
        # [/C #] = file compression type: 0 = none (default), 1 = NTFS, 2 = CAB

        $lv_C = "/C " + $C
        
        # [/G]  = generic mode -- SQL Server connectivity checks are not enforced; machine enumeration includes all servers, not just SQL Servers
        
        if ($G -eq $false)
        {
            $lv_G = ""
        }
        else 
        {
            $lv_G = "/G "
        }
        
        # [/R]  = registers the collector as a service

        if ($R -eq $false)
        {
            $lv_R = ""
        }
        else 
        {
            $lv_R = "/R "
        }
        
        # [/U]  = unregisters the collector as a service
        
        if ($U -eq $false)
        {
            $lv_U = ""
        }
        else 
        {
            $lv_U = "/U "
        }

        # [/A appname] = sets the application name to DIAG$appname.  If running as a service, this sets the service name to DIAG$appname

        if ([string]::IsNullOrWhiteSpace($A))
        {
            $lv_A = ""
        }
        else 
        {
            $lv_A = "/A " + $A
        }

        # [/L] = continuous mode -- automatically restarts when shutdown via /X or /E
        
        if ($L -eq $false)
        {
            $lv_L = ""
        }
        else 
        {
            $lv_L = "/L "
        }

        
        # [/X] = snapshot mode -- takes a snapshot of all configured diagnostics and shuts down immediately

        if ($X -eq $false)
        {
            $lv_X = ""
        }
        else 
        {
            $lv_X = "/X "
        }

        
        # [/B [+]YYYYMMDD_HH:MM:SS] = specifies the date/time to begin collecting data; "+" specifies a relative time

        if ([string]::IsNullOrWhiteSpace($B))
        {
            $lv_B = ""
        }
        else 
        {
            $lv_B = "/B " + $B
        }
        
        # [/E [+]YYYYMMDD_HH:MM:SS]  = specifies the date/time to end data collection; "+" specifies a relative time
        
        if ([string]::IsNullOrWhiteSpace($E))
        {
            $lv_E = ""
        }
        else 
        {
            $lv_E = "/E " + $E
        }

        # [/T {tcp[,port]|np|lpc|via}] = connects to sql server using the specified protocol

        if ([string]::IsNullOrWhiteSpace($T))
        {
            $lv_T = ""
        }
        else 
        {
            $lv_T = "/T " + $T
        }    


        if ($lv_U -eq "/U ")
        {
            $argument_list = $lv_U
        }
        else 
        {
            # special case if user typed /r instead of -R
            if ($ServiceState -eq "/r")
            {
                $lv_R = "/R "
            }

            $argument_list =  $lv_I + " " + $lv_O  + " " + $lv_P + " " + $lv_N + " " + $lv_M + " " + $lv_Q + " " + $lv_C + " " + $lv_G `
                + " " + $lv_R + " " + $lv_A  + " " + $lv_L  + " " + $lv_X + " " + $lv_B + " " + $lv_E + " " + $lv_T    
        }
        
    }


    Write-Host "Executing:  sqldiag.exe $argument_list"

    # launch the sqldiag.exe process
    Start-Process -FilePath SQLDiag.exe -ArgumentList $argument_list -WindowStyle Normal
}


main
