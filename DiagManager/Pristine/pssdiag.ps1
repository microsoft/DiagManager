
param
(

    [Parameter(Position=0,HelpMessage='/I xml_config_file',Mandatory=$false)]
    [string] $I = "pssdiag.xml",

    [Parameter(Position=1,HelpMessage='/O output_path',Mandatory=$false)]
    [string] $O = "output",

    [Parameter(Position=2,Mandatory=$false)]
    [string] $P =[string]::Empty,

    [Parameter(Position=3,Mandatory=$false)]
    [string] $N = "1"

    #[string] $X = [string]::Empty,

    
)


function main 
{
    Write-Host "The value of I is $I"

    $lv_I = "/I " + $I
    $lv_O = "/O " + $O
    
    if ([string]::IsNullOrWhiteSpace($P))
    {
        $lv_P = ""
    }
    else 
    {
        $lv_P = "/P " + $P    
    }

    $lv_N = "/N " + $N


    [string] $argument_list = $lv_I + " " + $lv_O  + " " + $lv_P + " " + $lv_N

    Start-Process -FilePath SQLDiag.exe -ArgumentList $argument_list -WindowStyle Normal
}


main
