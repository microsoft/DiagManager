--This is an example query
PRINT '-- dm_os_memory_clerks'
SELECT CONVERT (varchar(30), getdate(), 121) as runtime, * FROM sys.dm_os_memory_clerks
RAISERROR ('', 0, 1) WITH NOWAIT
