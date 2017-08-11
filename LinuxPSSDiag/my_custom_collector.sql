--This is an example query
-- If you need a custom TSQL collector place your queries in this file and enable the CUSTOM_COLLETOR=YES in pssdiag_collector.conf
/*
-- In this case dm_os_memory_clerks in the print statement will become your table name when imported by SQL Nexus
PRINT '-- dm_os_memory_clerks'
SELECT CONVERT (varchar(30), getdate(), 121) as runtime, * FROM sys.dm_os_memory_clerks
RAISERROR ('', 0, 1) WITH NOWAIT
*/

