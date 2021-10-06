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


set query=SET NOCOUNT ON
set query=!query!!NL!declare @starttime datetime = getdate(), @cnt int
set query=!query!!NL!while (1=1)
set query=!query!!NL!begin
set query=!query!!NL!select @cnt = count(^*) from sys.dm_exec_requests r join sys.dm_exec_sessions s on r.session_id = s.session_id where s.is_user_process =1 and r.cpu_time ^> 60000
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


rem execute the query 
sqlcmd -E -S%3 -Q"EXIT(!query!)"

REM If query batch returned -1 it means, the batch "timed out", didn't find any long-running CPU-bound queries
IF %ERRORLEVEL% EQU 78787878 (
echo batch timeout out, no high-CPU queries found
GOTO Exit
)


set /A cntr=0

REM if the query batch returned more than 5 queries, we will only process 5, else use the actual number returned

IF %ERRORLEVEL% GTR 5 (SET cntr=5) ELSE (SET cntr=%ERRORLEVEL%)
for /L %%x in (1,1, %cntr%) do bcp "select xmlplan from (SELECT TOP %1 ROW_NUMBER() OVER(ORDER BY (cpu_time) DESC) AS RowNumber, query_plan AS xmlplan FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_query_statistics_xml(session_id) WHERE r.cpu_time > 1) as x WHERE RowNumber =%%x" queryout "%2%%x.sqlplan" -T -c -S %3


:Exit