## Copyright (c) Microsoft Corporation.
## Licensed under the MIT license.

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [bool] $debug_on = $false
)

function Confirm-FileAttributes
{
<#
    .SYNOPSIS
        Checks the file attributes against the expected attributes in $expectedFileAttributes array.
    .DESCRIPTION
        Goal is to make sure that non-Powershell scripts were not inadvertently changed.
        Currently checks for changes to file size and hash.
        Will return $false if any attribute mismatch is found.
    .EXAMPLE
        $ret = Confirm-FileAttributes
#>

    if ($debug_on -eq $true)
    {
        $DebugPreference = "Continue"
    }

    


    Write-Host "Validating attributes for non-Powershell script files"

# TODO: deal with ManualStart, ManualStop and pssdiag_xevent.sql

    $validAttributes = $true #this will be set to $false if any mismatch is found, then returned to caller

    $expectedFileAttributes = @(
         [PSCustomObject]@{Algorithm = "SHA512"; Hash = "A4BDA81611E1E777D2C8F5A36B295B1B2CC7DC67E40CEA8445E099F6C757D633B8EACC88C54E8FB1AD6D00E6186668B15AE8600C47E375F35F21ECDD97560033"; FileName = ".\AlwaysOnDiagScript.sql"; FileSize = 18186}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "C0D633F8AA0C7FAE10AB0E596DD710E2CBC673A4BFE93F124B14002E8F65F116DCDCC9CB94EA7CFCF7DBABC071947382DED4592C535FE6B9C00FC34A1D091599"; FileName = ".\AlwaysOnGetClusterLogs.cmd"; FileSize = 138}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "55B8B497973F9C0980C696A0599ECAF3401C4A02FBEBFDC78608CA3354AE01E1EA03508FB558AA4548EA74988C1BA9E5DFAE310F6D60A23B38D39B310A9A84A6"; FileName = ".\AutoUserDump.bat"; FileSize = 2829}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "41938EE0E0ADE87E0D26F88C28F8A70CC54D0AE8CA21657AD5F72918E364F4C3972F1C6C86267A79D39C2D418BF89A60AE2EA2EF9998084DFEA85F9DC8D61478"; FileName = ".\build.cmd"; FileSize = 609}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "4E2E0C0018B1AE4E6402D5D985B71E03E8AECBB9DA3145E63758343AEAC234E3D4988739CCE1AC034DDA7CE77482B27FB5C2A7A4E266E9C283F90593A1B562A2"; FileName = ".\ChangeDataCapture.sql"; FileSize = 4672}
		,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "72B955257DD659BC09EDF3621F90BA2731BE817F02972F2AFBDE0BB374AFA43FA582C72B7A6562A2C4950F435FCD7019D5DC354449CD4667F33D55763007694F"; FileName = ".\Change_Tracking.sql"; FileSize = 5112}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "11B4EEDFBF689C718E5CE60A4F6B46A899E0E2C617E5311BAE8ED81FA702000FC7AE8E09DB796163C0B2B84DC621884EEA02D47999C04DA8F096F1164ABDB3AE"; FileName = ".\ClearOrphanedBLGs.cmd"; FileSize = 1085}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "BF6CF04DB43D9C41E34C12A81DFB6DE7D9187BA2EC89EF0AC5AE8BB842CD00EC1FBDCB7870249AE5F2A9950FE0FD85A3BE6275856504F49BF578A9693E49063C"; FileName = ".\CMemthread.sql"; FileSize = 461}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "75B822DAAED573CEC075EC39AF882FED3340B8809235AAB5DBFB5673008474DA8EF2B57ECC5F563668F8F526E24B22555B33F0D5167F5B83D7E16D41271F307A"; FileName = ".\collecterrorlog.cmd"; FileSize = 263}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "BC7120451387E14695D1E6AAC25783C2C7299A131672D0BB28CB6971DEE53DF23D82E6A5D2E63D20DCC0EEE8BB26A8D3E93B2EFF7E400641FA959BE829B9FFFD"; FileName = ".\collecterrorlog.sql"; FileSize = 361}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "F5AB1122719AC332E9359A3A4884BF6FA922383236858A0884EF6D9CEBD80ED2151AF7E95A9C4B6019C2A55A0A987037E16FD0443E7E487385502863C3A0A0E8"; FileName = ".\ColumnStore.sql"; FileSize = 4970}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "AEBBAB953A7187281EBCAE85FC38F3FCDBA600220FDFC3A29348626B394D2FC4E938065F1EF3375EB91A962F31572704E72814D76DB8264C35FFF01D55049BA2"; FileName = ".\ConnectivityTest.bat"; FileSize = 3746}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "7E794E2322F58933E8769FB680F3B232B3287EFAB71FF2D709273704BD578866E5A640FEBB935B9170570136C49905B52CD7BB7D4986D92D280B40B7F2F27C64"; FileName = ".\DefineCommonVars.cmd"; FileSize = 4321}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "99F853F56BD0253176F12678D25D1F564E3BD5C8E1432E669E3AF6126DD3169CAF2ECB6D3B03B08E65934B8BDD694B6C9708076FDFE003C293BA7346C8D58C3E"; FileName = ".\DefineSQLInstanceSetupPaths.cmd"; FileSize = 2410}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "710C24EC35021A35DC439BFFF59C2B98F3083A8273B4B430361656C2E264E9F7CDCF82F2916D2E8DF9CB1249CD9D403BF00B444FA360F34351CBBB9F7A2F514B"; FileName = ".\DoLooksAlive.bat"; FileSize = 7774}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "FC627ABB404C01F9E1EF8A533F8D607B1FFF22D94E4E89D2A124B396F572724B9004D1B3B52240E6D2B1917FD9A0519189E88688BC72575462143975AC6134FF"; FileName = ".\errorlogs.js"; FileSize = 7731}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "F3687C92E9B3100421728B9CF8B76481CA4163694ED2BC3E5410D7D35934EDC8A6638FB4C8AF01F8BF612BE8D14DEF09B96A688DE83C99038B99510B97DF1708"; FileName = ".\FTS_Collector.sql"; FileSize = 13804}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "F539B33196C4BC259E2F9983D31F05DEAC93BC23794197A9580F9BC9E15F0274E5CC4673E36E04495ABF3A59CF78792489DE1537AEFB738DF179B745B8B43555"; FileName = ".\fts_info.sql"; FileSize = 5846}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "216681E0F3541DAD01652B4D319B3C6619EAC8684F33694F52DC3DC509B0D80D7E1B7F121642A0C275D60F1581B00089D0AD01A713745EEC3F0FFAA1A38EB3D4"; FileName = ".\GetAllSQLInstancePIDS.cmd"; FileSize = 734}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "96A70F624E21EAA4118AC10EE2D0168F6F4369886B218571237EFF9063A1C1FAAB749B4FDD57DFAD411262981C23540EE7CCD2906ED44C2E4F1664F282F4D193"; FileName = ".\GetFileVer.CMD"; FileSize = 1317}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "1A3BD5E09DAFCAD9F70BB0128007BD0BAF5CDD6916DA7A4F9815F8D92674D9EFA4252654B20AEE5CFAC3BAEABFB80DD03AC39FD4B11975B2D81174D289DA27DD"; FileName = ".\GetRegValue.CMD"; FileSize = 1117}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "7D890D6E26FD93676CDC7C5525D0D2F35BA1FEB8A0C2344C157922668798734907C5EC046B40F7DB1440E90E26406036B2AA44582F17B35B1789E122F323C30B"; FileName = ".\GetSQLInstancePID.CMD"; FileSize = 2118}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "9E6A3A9EDBBCDE9DA84D7635396977B6FEF6512A51A9A396004A6EFF67CEF4C99EE61CBD9CCE1776B55CD78442F1CA3300A99E170CBF3F99410364B45932DF9E"; FileName = ".\get_dbccloginfo.sql"; FileSize = 494}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "45B6F82A7993AABE6C1CB1ACE51F21EEA68CFB624F101F3E0604E41E20FCAAE48D50FC18EF165CC46F8C6450E6182C9101294550527DD5679A905E5D1E42E991"; FileName = ".\get_dbmirroringinfo.sql"; FileSize = 5138}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "FF0BE2ACCF32E5557C70774E480B48266355D928CDE07E1A265459D1FB660C86531AE354F5379263F99EDEBD4F4C1D37D0BED7919F3D92D19B65344432A9BBC7"; FileName = ".\get_dbmirroringinfo.vbs"; FileSize = 2556}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "A81FF0564F8D79674C36461D86E4338C0C28C7995CDEEE970107DD8FB3915ABC68380A1BCB01EFD8A839F26BCD271880118F6E0447972D37834DB0EB4C690CC8"; FileName = ".\get_tasklist.cmd"; FileSize = 373}
		,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "46D03FC5E13114C1DA826DB266EA5A5219E15510709EBEC416D9F30858325FE0F5E6AD94247431A34E8AAD09B62B15919FB3058F2B68D868703CF959ADC707DA"; FileName = ".\HighCPU_perfstats.sql"; FileSize = 5334}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "BA125F5D7F76C0B6D70A8B198532EE9DE6B179DAFECBC2D5AFE256DA569900CC483381EB1D717817FB7AB5AEF6DD8C30FD8A73819BA3B870C5838FDE37E9659E"; FileName = ".\In_Memory_OLTP.sql"; FileSize = 2273}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "804B3E27309C23E9530BF475DBD8DA52D1DFA334D7A118DE66B77E4E8182BA8FAC1F938C2FDC1D4CB11F73295354ADEECC33075BF7B87F2C505C03C1BB8E86FB"; FileName = ".\linked_server_config.sql"; FileSize = 3638}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "98B7925B2167F6610AA09DD832B04388D863AD2D26193DF31A665278C0C4BB40D5587CD981A052DD4CAF90454DEA211CB68D5291D02F5004482497303D05921C"; FileName = ".\LooksAliveBatch.sql"; FileSize = 366}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "78CDEFB86A57A39A551DD8D7D38028AF6B8073C4175731AD014F9E90F136C5E0AFD0074C19CA4048492EFF5297867FF663531C90C3B012D0078561BCFD5F4177"; FileName = ".\ManualStart.cmd"; FileSize = 4015}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "7698E15AC47A1735C1C6D630CC4A451F13F80D3B3F578BA0802CDAD43DB224D78E9498B28B40FB929B12FCEB7129560565FC4AADBEE888863E268BC73B378AD0"; FileName = ".\ManualStop.cmd"; FileSize = 1727}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "CD1564EB4C7A1A404C2C6AD67417502257584F91BB57603E0A8B9940E3090252F9C8723454CB052803D911C9B084A6058993B2032BE9E9DCE906072C329743EA"; FileName = ".\ManualUserDump.bat"; FileSize = 1220}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "46B20531696B31628EAA61B09609B15C6E2DE7E6082F473F57BAF8F8D4558C128115AD6FCEEF99668F5FD0AECEBC66E167CB8A4967227AE927E7C0D44F3D520C"; FileName = ".\MiscPssdiagInfo.sql"; FileSize = 14775}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "04E8C86AA2747E9E33F5A83C40C5023CBDD5366B3AC2882A346E264921B4BFFB6A6651CFC1FE5003E6C6C9E6711C58A0A7D9CB5158C46BCCDDCA011AB1C019FE"; FileName = ".\MSDiagProcs.sql"; FileSize = 189179}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "5D0255A2273CFCE8DDF47C1C4BA6148C2741C73B62D3B63B6F7050559A9B15653DE62CEA9D47604E2878A434A2213A48D4BD93E8E11DF8608AA54AD27985F79A"; FileName = ".\multicopy.cmd"; FileSize = 266}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "8402D11B175A84028AC3B6AABF98CF3A307BE9CD6DFE0D0A5B739D302A014D4758ADF10B7882549FF4D7CFBA7AC6598C6E3F2A04D5C30E0D67790E9ABEF2F821"; FileName = ".\multicopyr.cmd"; FileSize = 2077}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "8366A86E01D3430AF1DF9E51A852324A64D5D63DAD3E68EF6AF240E29FAA8A397CF06390A05AB4CFF97FF3B65A825FAFA11381D2D10045AAE344FE1BEFE90A33"; FileName = ".\My Collector Script.sql"; FileSize = 47}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "0DA7B5F39B23196B16913AB660099B82F384E1C1757FF524894A37867010965E7E28ED87D87DAB00632482D12417DB9D21F1B52B4A8D8750192CECF39E57A448"; FileName = ".\OutputActiveTimeBias.CMD"; FileSize = 719}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "224D5E6E4BD71A3063F6F4A804A884254CE70416F78E15B1C33BC3D0FAA25B50EBBC49B2CE193E64B9A3BAE8449095FA80851258DF61B83FD6AADA56F6549B48"; FileName = ".\OutputCurTime.cmd"; FileSize = 389}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "6B57D47F10FDAA53B414200637C2B48CDE5D511FFD20D5947EC0A69E68C88BC87B4EEB7B2F71E2462D33B4CE33389618AE7E56076BA68F1BCF3F306E413D86C5"; FileName = ".\OutputCurTime.vbs"; FileSize = 1122}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "5CF137CA8F4C34DAD59D1C21D41F1C13D4AA933B7AB593272D4C785EE3F087689BEB9FBA0D163DD21AF2F4C68C574B5C3D33979ACE92E9D747503A1490671A9A"; FileName = ".\PolyBase.sql"; FileSize = 1959}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "782D8FFD9E46AAEA7ED70A608A2BAD37E1FAB7DDF6A8FF6423A365B69F0CC2DEBA753EF1E0C897412B6C115DC23A472320AF1465AFE702E1ED91C8123CA1E36C"; FileName = ".\PowerPlan.VBS"; FileSize = 650}
		,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "2E209F7D1ECA92396A620FB0B92DED937EBFF1F59A017B47A27672A151C4F32E8189CF1AB66E082946219AAEA091B6EF0D712C1D6080A19006702273D60957D2"; FileName = ".\Profiler Traces.sql"; FileSize = 2743}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "825C5281C6D1654A2E557814F751E7A50F6F525E9CF3529E4F1EDBE0FB68E42DC80517CD297CDE658540A6383EE54A2A5239ADFA994175274F8D96861C9F4DDB"; FileName = ".\Query Store.sql"; FileSize = 2589}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "6707EEE5E26A79C22AB0387B900EF4014599D33244E1E19CCB85206D58B26A659BE8E7585BCCC30FC7CB5E92C1348A30E94A8EC72DF04AEEDDB5E641DCF2DCE0"; FileName = ".\QueryNeverCompletes_perfstats.sql"; FileSize = 6854}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "4B7745C8EEB9BFE49AD89B481591F3FAA1FAC8B1D6909A8C43C091CED79F609E57274284CB23FADB14447979AC11A0427F379E1D509D7CA33BADF0F9D42F52CB"; FileName = ".\Repl_Metadata_Collector.sql"; FileSize = 50941}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "902A5292AF20AD580AD196828C7EAA0E97E35308E919A4E1999F92C6486A09147690FF493752316613EDE36E41ACE5D743D9D52E69C4D678FEE1D6E03C11A4B9"; FileName = ".\rtrim.vbs"; FileSize = 423}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "15C8D2F26416FFA1C0A913A2E22A4448CB1E777D3EA7558F4E58C83C7462A2069BEA6AE687C741D89059DBB98C52FA30E900324EC9D98261A13E1DFE083A19C7"; FileName = ".\run_in_dir.cmd"; FileSize = 49}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "0E5EDDED466F2AE758E7B1CE1A9C66952F29251BB3B980145688A969B76711AFAE60528E2B9942E43BA268A5D50BCADD88FBE354184C47F6D456FDAE50DFB9A0"; FileName = ".\SetSqlEnvVariables.cmd"; FileSize = 1008}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "AE3BFFB70FAC3DCCFA61192DF515635832D819545B84F915AF63378C33422E8FCAC23BEA128B91907F420E46524321866904C24CCA6A352B85E9519CB2A35EDD"; FileName = ".\SetupVars.bat"; FileSize = 1126}
      	,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "2AB2AD47A7CAACAA586490B35D1453F665E3872B1FC0BE4ADC18D67ADCA6F5E73368A7F72F6B2F17FCD7BE38421144A5108D2176C3D7AD6C28D2181DC9381599"; FileName = ".\SQL Server Perf Stats Snapshot.sql"; FileSize = 34821}
	    ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "A9AD7AFB19C5AC17B384A28C0C7E3B505ECAEAD8CFCCE43688D2A36648731456AEC5E63443CE459A8AD62552839B98CA7A424DE72C70F41B43556EE03BCB8B28"; FileName = ".\SQL Server Perf Stats.sql"; FileSize = 71222}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "7A8489AD9CF344B2A96E5EA37710307DB992CC2B054BD3B97217169157C4D84064183702A1172B0227716FA2B802CFB746B9F0C80C8C4C5EB0D2051BB1B8223C"; FileName = ".\sql_module_list.cmd"; FileSize = 346}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "6896BCA7372755C75063854A3030C5D57226072D64E271938C6D4FC00BDD8446983CF2D88CB726C30C26D9E4E7AEF2BA0FC070196214F60F1E91624E8AB487DA"; FileName = ".\SQL_Server_Mem_Stats.sql"; FileSize = 16865}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "5CB4E3F3B3FD99E90603D84AD8C18C6A06E663210C2FD6FB42718431CACB7F84E5DFA3B172C1E065F70504B415D4EE9AAB2CFE0333A9CD28381D73E39C77A781"; FileName = ".\SSB_pssdiag.sql"; FileSize = 10531}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "D5DB0DC73327FAA34A67DFC7EFFED7A740994AFACE122DEAC2F3905F52747FFF1D1DB83518EA3F7DC937A045A6E5EA5DC947C6E00BE0591640371B88B5ED7DA7"; FileName = ".\StartFromPSSDiag.bat"; FileSize = 1607}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "93C312346BD00C02B7241813397C9B99F9400BB2ADF31077E5B4BA1FF7ABAE656490AF3D049B3F2D621D93C972157F860E5C2BCF4D7EC4A52904B4EACD7FF6D3"; FileName = ".\StartPSS.bat"; FileSize = 310}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "ABA1A57AB4E5FAA9D3D783C29AFBB74E874A58E50A2889661F7CA57EACC9FB4A9B4D7182B069A4DBE815E951370E7BAC78FDB2A2D0D601458A2A2C7B970A2E06"; FileName = ".\StretchDB.sql"; FileSize = 29}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "CFE65260650685461D37F64B4DDC398BC4FA651049EAD2D351C34F40EAF3DB958D02029B615E1511D8CB446ABD8C122CBC361178CBCC46CD1D9233268656A4E8"; FileName = ".\TempDB_and_Tran_Analysis.sql"; FileSize = 8984}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "81EB149D0182A4E7FD62007B69A3658E1126F9723DB386BD358CA7CAC695431AFB2684D4A40D7F7A4E07F2FB727B4F904507CC6E0A6F03B5BBE9323AB0F60681"; FileName = ".\TopCPUQueryShowPlanXML.bat"; FileSize = 883}
        ,[PSCustomObject]@{Algorithm = "SHA512"; Hash = "0DC99DC0CEDCFF9ECA0B3147CE6F004185867BCE74090360F9509B2FDED01FE3E1883E9609214FB29E989CCEC774DC2C2FE3F2D552E7BCABBAD6AB494EFAC882"; FileName = ".\WaitForExe.cmd"; FileSize = 297}

)

    # global array to keep a System.IO.FileStream object for each of the non-Powershell files
    # files are opened with Read sharing before being hashed
    # files are kept opened until SQL LogScout terminates preventing changes to them
    #[System.Collections.ArrayList]$Global:hashedFiles = [System.Collections.ArrayList]::new()
    $Global:hashedFiles = New-Object -TypeName  System.Collections.ArrayList

    
    foreach ($efa in $expectedFileAttributes) 
    {
        
        try
        {
            Write-Debug ("Attempting to open file with read sharing: " + $efa.FileName)
            
            $cur_file = $efa.FileName

            if ((Test-Path -Path $cur_file) -eq $true)
            {
                $cur_file = Convert-Path -Path $cur_file
                
                $fstream = [System.IO.File]::Open($cur_file, 
                [System.IO.FileMode]::Open, 
                [System.IO.FileAccess]::Read, 
                [System.IO.FileShare]::Read)

                
                Write-Debug ("FileName opened = " + $fstream.Name)
            }
            else 
            {
                Write-Debug ("File " + $efa.FileName + " not present")
                Continue 
            }
            

            # open the file with read sharing and add to array
            [void]$Global:hashedFiles.Add($fstream)
            

        } catch {
            $validAttributes = $false
            Write-Host ("Error opening file with read sharing: " + $efa.FileName ) -ForegroundColor Red
            Write-Host $_ -ForegroundColor Red

            return $validAttributes
        }

        Write-Debug  ("Validating attributes for file " + $efa.FileName)

        try {
            $file = Get-ChildItem -Path $efa.FileName

            if ($null -eq $file){
                throw "`$file is `$null"
            }
        }
        catch {
            $validAttributes = $false
            Write-Host "" -ForegroundColor Red
            Write-Host ("Could not get properties from file " + $efa.FileName) -ForegroundColor Red
            Write-Host $_ -ForegroundColor Red
            Write-Host "" -ForegroundColor Red
            return $validAttributes
        }

        try {
            $fileHash = Get-FileHash -Algorithm $efa.Algorithm -Path $efa.FileName

            if ($null -eq $fileHash){
                throw "`$fileHash is `$null"
            }
    
        }
        catch {
            $validAttributes = $false
            Write-Host "" -ForegroundColor Red
            Write-Host ("Could not get hash from file " + $efa.FileName) -ForegroundColor Red
            Write-Host $_ -ForegroundColor Red
            Write-Host "" -ForegroundColor Red
            return $validAttributes
        }

        if(($file.Length -ne $efa.FileSize) -or ($fileHash.Hash -ne $efa.Hash))
        {
            $validAttributes = $false
            Write-Host "" -ForegroundColor Red
            Write-Host ("Attribute mismatch for file: " + $efa.FileName) -ForegroundColor Red
            Write-Host "" -ForegroundColor Red
            Write-Host ("Expected File Size: " + $efa.FileSize) -ForegroundColor Red
            Write-Host ("Actual   File Size: " + $file.Length) -ForegroundColor Red
            Write-Host "" -ForegroundColor Red
            Write-Host ("Expected Hash: `n" + $efa.Hash) -ForegroundColor Red
            Write-Host ("Actual   Hash: `n" + $fileHash.Hash) -ForegroundColor Red
            Write-Host "" -ForegroundColor Red
            
        } else {
            Write-Debug ("Actual File Size matches Expected File Size: " + $efa.FileSize + " bytes")
            Write-Debug ("Actual Hash matches Expected Hash (" + $efa.Algorithm + "): " + $efa.Hash )
        }

        if (-not($validAttributes)){
            # we found a file with mismatching attributes, therefore backout indicating failure
            return $validAttributes
        }

        
        $fstream.Close()
        $fstream.Dispose()


    } #foreach

    return $validAttributes
}

# use to calculate filehash values when files are changed

function Get-FileAttributes([string] $file_name = ""){
<#
    .SYNOPSIS
        Display string for $expectedFileAttributes.
    .DESCRIPTION
        This is to be used only when some script is changed and we need to refresh the file attributes in Confirm-FileAttributes.ps1
    .EXAMPLE
        . .\Confirm-FileAttributes.ps1
        Get-FileAttributes
#>

    [int]$fileCount = 0
    [System.Text.StringBuilder]$sb = New-Object -TypeName System.Text.StringBuilder

    [void]$sb.AppendLine("`$expectedFileAttributes = @(")
    
    foreach($file in (Get-ChildItem -Path . -File -Filter $file_name)){
        
        # Powershell files are signed, therefore no need to hash-compare them
        # "Get-ChildItem -Exclude *.ps1 -File" yields zero results, therefore we skip .PS1 files with the following IF
        if (".ps1" -ne $file.Extension){
            
            $fileCount++

            # append TAB+space for first file (identation)
            # append TAB+comma for 2nd file onwards
            if($fileCount -gt 1){
                [void]$sb.Append("`t,")
            } else {
                [void]$sb.Append("`t ")
            }
    
            $fileHash = Get-FileHash -Algorithm SHA512 -Path $file.FullName

            $algorithm = $fileHash.Algorithm
            $hash = $fileHash.Hash
            $fileName = ".\" + $file.Name
            $fileSize = [string]$file.Length

            [void]$sb.AppendLine("[PSCustomObject]@{Algorithm = `"$algorithm`"; Hash = `"$hash`"; FileName = `"$fileName`"; FileSize = $fileSize}")

        }

    }

    [void]$sb.AppendLine(")")
    
    Write-Host $sb.ToString()
}