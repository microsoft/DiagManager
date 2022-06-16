DECLARE @SQL_COUNTER_INTERVAL int
SET @SQL_COUNTER_INTERVAL = 15
DECLARE @runtime datetime

WHILE (1=1)
BEGIN
SET @runtime = GETDATE()

print ''
print '-- sql server performance counters --'

SELECT     CONVERT (varchar(30), @runtime, 121) as runtime, 
* FROM sys.dm_os_performance_counters

RAISERROR ('', 0, 1) WITH NOWAIT

WAITFOR DELAY @SQL_COUNTER_INTERVAL
END

