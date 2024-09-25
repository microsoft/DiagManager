--This is an example query
-- If you need a custom TSQL collector place your queries in this file and enable the CUSTOM_COLLETOR=YES in pssdiag_collector.conf, works only for sql_perf.scn type of scenarios.
/*
examples

-- In this case dm_os_memory_clerks in the print statement will become your table name when imported by SQL Nexus
PRINT '-- dm_os_memory_clerks'
SELECT CONVERT (varchar(30), getdate(), 121) as runtime, * FROM sys.dm_os_memory_clerks
RAISERROR ('', 0, 1) WITH NOWAIT

-- if you want DMV to run in loop during PSSDiag execution, below is an example that will in loop every 30 seconds, DO NOT use for complex TSQL Script that returns large resultset. 
PRINT '-- sys.dm_os_memory_brokers'
DECLARE @runtime datetime

WHILE 1=1
begin
	select CONVERT (varchar(30), @runtime, 121) as runtime,* from sys.dm_os_memory_brokers
	RAISERROR ('', 0, 1) WITH NOWAIT
	WAITFOR DELAY '00:00:30'
end

-- if you have multiple simply DMVs to run, then create new file with name that start with my_custom_collector_<name>.sql for example(my_custom_collector_DMV1.sql, my_custom_collector_DMV2.sql ...etc)

*/
