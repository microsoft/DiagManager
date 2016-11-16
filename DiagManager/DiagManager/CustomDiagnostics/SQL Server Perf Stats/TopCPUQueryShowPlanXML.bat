REM @echo off
REM -- TOP CPU SHOWPLAN_XML batch file 
REM -- This batch file get the top 10 CPU queries show plan xml 
REM
REM Usage: 
REM    TopCPUQueryShowPlanXML.bat <TOP N queries> <Output Path> <SQL Server Instance name> 
REM
REM Example: 
REM    TopCPUQueryShowPlanXML 10 C:\temp\Shutdown_ DSDAUTO1 
REM

for /L %%x in (1,1, %1) do bcp "select xmlplan from (SELECT   ROW_NUMBER() OVER(ORDER BY (highest_cpu_queries.total_worker_time/highest_cpu_queries.execution_count) DESC) AS RowNumber, CAST(query_plan as XML) xmlplan FROM (SELECT TOP 5 qs.plan_handle, qs.total_worker_time, qs.execution_count  FROM sys.dm_exec_query_stats qs ORDER BY qs.total_worker_time DESC) AS highest_cpu_queries CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS q     CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS p  ) as x where RowNumber =%%x" queryout "%2%%x.sqlplan" -T -c -S %3
