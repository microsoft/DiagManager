@echo off
setlocal enableDelayedExpansion
REM @echo off
REM -- TOP CPU SHOWPLAN_XML batch file
REM -- This batch file get the top 10 CPU queries show plan xml
REM
REM Usage:
REM TopCPUQueryShowPlanXML.bat <TOP N queries> <Output Path> <SQL Server Instance name>
REM
REM Example:
REM TopCPUQueryShowPlanXML 10 C:\temp\Shutdown_ DSDAUTO1
REM



set NL=^


set query=IF (OBJECT_ID('tempdb.dbo.original_config_tf_7412')) IS NULL
set query=!query!!NL!CREATE TABLE tempdb.dbo.original_config_tf_7412 ([ID] [bigint] IDENTITY(1,1) NOT NULL,[TraceFlag] INT, Status INT, Global INT, Session INT)
set query=!query!!NL!INSERT INTO tempdb.dbo.original_config_tf_7412 EXEC('DBCC TRACESTATUS (7412)')
set query=!query!!NL!IF EXISTS (SELECT 1 FROM tempdb.dbo.original_config_tf_7412 WHERE GLOBAL = 0 AND TraceFlag = 7412) DBCC TRACEON (7412, -1)
set query=!query!!NL!SET NOCOUNT ON
set query=!query!!NL!declare @starttime datetime = getdate(), @cnt int
set query=!query!!NL!while (1=1)
set query=!query!!NL!begin
set query=!query!!NL!select @cnt = count(^*) from sys.dm_exec_requests r join sys.dm_exec_sessions s on r.session_id = s.session_id CROSS APPLY sys.dm_exec_query_statistics_xml(r.session_id) AS x where s.is_user_process =1 and r.cpu_time ^> 60000
set query=!query!!NL!if @cnt ^> 0
set query=!query!!NL!begin
set query=!query!!NL!select @cnt
set query=!query!!NL!break
set query=!query!!NL!end
set query=!query!!NL!if (DATEDIFF (MINUTE,@starttime, getdate()) ^> 10)
set query=!query!!NL!begin
set query=!query!!NL!select 78787878
set query=!query!!NL!break
set query=!query!!NL!end
set query=!query!!NL!waitfor delay '00:00:10'
set query=!query!!NL!end

for /L %%y in (1,1, 3) do (
rem execute the query 
sqlcmd -E -S%2 -Q"EXIT(!query!)"

REM If query batch returned -1 it means, the batch "timed out", didn't find any long-running CPU-bound queries
IF !ERRORLEVEL! EQU 78787878 (
echo batch timeout out, no high-CPU queries found
GOTO Exit
)

set /A cntr=0
REM if the query batch returned more than 5 queries, we will only process 5, else use the actual number returned
if !ERRORLEVEL! GTR 5 (
	set /a cntr=5
) else (
	set /a cntr=!ERRORLEVEL!
)
	for /L %%x in (1,1, !cntr!) do (
		bcp "select xmlplan from (SELECT TOP !cntr! ROW_NUMBER() OVER(ORDER BY (r.cpu_time) DESC) AS RowNumber, x.query_plan AS xmlplan, t.text AS sql_text FROM sys.dm_exec_requests AS r INNER JOIN sys.dm_exec_sessions AS s ON r.session_id = s.session_id CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t CROSS APPLY sys.dm_exec_query_statistics_xml(r.session_id) AS x WHERE s.is_user_process = 1 AND r.cpu_time > 60000 ) as x WHERE RowNumber =%%x" queryout "%1_run%%y_plan%%x.sqlplan" -T -c -S %2
	)
	(echo %1 | findstr /i /c:"Startup" >nul) && (IF %%y LSS 3 (powershell -command "Start-Sleep -s 120")) || (GOTO Exit)
)
:Exit