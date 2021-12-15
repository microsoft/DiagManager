param($pssdiagprefix, $SQLSERVERinstance)

function callsql ([string]$sqlcmdparam, [int] $CmdTimeout=30, [string] $servernamesql)
{
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=" + $servernamesql + ";Database=master;Integrated Security=True"
    $SqlConnection.Open()
    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $SqlCmd.CommandText = $sqlcmdparam
    $SqlCmd.Connection = $SqlConnection
    $SqlCmd.CommandTimeout = $CmdTimeout
    $ret_value = $SqlCmd.ExecuteScalar()
    $SqlConnection.Close()
    return $ret_value
}

#Version check, exit if AV versions
$query_sqlver = "IF ((LEFT((CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion'))),2) = 14) AND ((SUBSTRING((CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion'))),6,4)) < 3025))
    OR ((LEFT((CONVERT(VARCHAR(128), SERVERPROPERTY ('productversion'))),2) = 13) AND ((SUBSTRING((CONVERT(VARCHAR(128),SERVERPROPERTY ('productversion'))),6,4)) < 4474))
	BEGIN
		SELECT 1
	END"
$validver = callsql -sqlcmdparam $query_sqlver -CmdTimeout 60 -servernamesql $SQLSERVERinstance

IF ($validver -eq 1){
    EXIT
}


#enable mandatory traceflag and create restore to original configuration logic
If ($pssdiagprefix -ilike "*startup*"){
    $query_sqlcmdtf = "IF (OBJECT_ID('tempdb.dbo.original_config_tf_7412')) IS NULL
        BEGIN
            CREATE TABLE tempdb.dbo.original_config_tf_7412 ([ID] [bigint] IDENTITY(1,1) NOT NULL,[TraceFlag] INT, Status INT, Global INT, Session INT)
        END
        INSERT INTO tempdb.dbo.original_config_tf_7412 EXEC('DBCC TRACESTATUS (7412)')
        IF EXISTS (SELECT 1 FROM tempdb.dbo.original_config_tf_7412 WHERE GLOBAL = 0 AND TraceFlag = 7412) DBCC TRACEON (7412, -1)"

callsql -sqlcmdparam $query_sqlcmdtf -CmdTimeout 60 -servernamesql $SQLSERVERinstance
}

#count existing 60 seconds CPU queries, startup loop 3 times 
While ($runs –lt 3) {
    $runs = $runs +1
    $query_sqlcmd= "SET NOCOUNT ON
    declare @starttime datetime = getdate(), @cnt int
    while (1=1)
    begin
        select @cnt = count(*) from sys.dm_exec_requests r join sys.dm_exec_sessions s on r.session_id = s.session_id CROSS APPLY sys.dm_exec_query_statistics_xml(r.session_id) AS x where s.is_user_process =1 and r.cpu_time > 60000
        if @cnt > 0
        begin
            select @cnt
            break
        end
        if (DATEDIFF (MINUTE,@starttime, getdate()) > 10)
        begin
            select 78787878
            break
        end
        waitfor delay '00:00:10'
    end"

    $querycount = callsql -sqlcmdparam $query_sqlcmd -CmdTimeout 900 -servernamesql $SQLSERVERinstance



    IF ($querycount -eq 78787878){
        Write-Output "The batch stoped after 10 minutes, no high-CPU queries found"
        EXIT
    }

    $cntr = 0
    IF ($querycount -gt 5){
        $cntr = 5
    } ELSE {
        $cntr = $querycount
    }

#collect plans
    While ($numbers –lt $cntr) {

        $numbers = $numbers + 1

        $sqlbcpquery = "select xmlplan from (SELECT TOP " + $cntr +" ROW_NUMBER() OVER(ORDER BY (r.cpu_time) DESC) AS RowNumber, x.query_plan AS xmlplan, t.text AS sql_text FROM sys.dm_exec_requests AS r INNER JOIN sys.dm_exec_sessions AS s ON r.session_id = s.session_id CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t CROSS APPLY sys.dm_exec_query_statistics_xml(r.session_id) AS x WHERE s.is_user_process = 1 AND r.cpu_time > 60000 ) as x WHERE RowNumber =" + $numbers
        $planlocation = $pssdiagprefix + "_run" + $runs + "_plan" + $numbers + ".sqlplan"
        bcp $sqlbcpquery QUERYOUT $planlocation -T -c -S $SQLSERVERinstance

    }
    Clear-Variable numbers
    
    If (($pssdiagprefix -ilike "*startup*") -and ($runs -lt 3)){
        Start-Sleep -s 120
    } Else {
        EXIT
    }
}

Clear-Variable runs
Clear-Variable pssdiagprefix