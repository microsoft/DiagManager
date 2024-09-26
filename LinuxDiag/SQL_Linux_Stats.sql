USE tempdb
GO
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID ('sp_perf_stats_infrequent12','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_infrequent12
GO
CREATE PROCEDURE sp_perf_stats_infrequent12 @runtime datetime, @firstrun int = 0 AS 
  SET NOCOUNT ON
  DECLARE @queryduration int
  DECLARE @querystarttime datetime
  DECLARE @qrydurationwarnthreshold int
  DECLARE @cpu_time_start bigint, @elapsed_time_start bigint
  DECLARE @servermajorversion int
  DECLARE @msg varchar(100)
  DECLARE @sql nvarchar(max)

  IF @runtime IS NULL 
  BEGIN 
    SET @runtime = GETDATE()
    SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
    RAISERROR (@msg, 0, 1) WITH NOWAIT
  END
  SET @qrydurationwarnthreshold = 750

  SELECT @cpu_time_start = cpu_time, @elapsed_time_start = total_elapsed_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID

  /* SERVERPROPERTY ('ProductVersion') returns e.g. "9.00.2198.00" --> 9 */
  SET @servermajorversion = REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')


  /* Resultset #1: SQL processor utilization */
  PRINT ''
  RAISERROR ('-- Recent SQL Processor Utilization (Health Records) --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  if @firstrun=1
  begin
  SELECT /*TOP 5*/
    
      CONVERT (varchar(30), @runtime, 126) AS 'runtime', 
      record.value('(Record/@id)[1]', 'int') AS 'record_id',
      CONVERT (varchar, DATEADD (ms, -1 * (inf.ms_ticks - [timestamp]), GETDATE()), 126) AS 'EventTime', [timestamp], 
      record.value('(Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS 'system_idle_cpu',
      record.value('(Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS 'sql_cpu_utilization' 
    FROM sys.dm_os_sys_info inf CROSS JOIN (
      SELECT timestamp, CONVERT (xml, record) AS 'record' 
      FROM sys.dm_os_ring_buffers 
      WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
        AND record LIKE '%<SystemHealth>%') AS t
    ORDER BY record.value('(Record/@id)[1]', 'int') DESC
   end
  else
  begin
	  SELECT TOP 5
      CONVERT (varchar(30), @runtime, 126) AS 'runtime', 
      record.value('(Record/@id)[1]', 'int') AS 'record_id',
      CONVERT (varchar, DATEADD (ms, -1 * (inf.ms_ticks - [timestamp]), GETDATE()), 126) AS 'EventTime', [timestamp], 
      record.value('(Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS 'system_idle_cpu',
      record.value('(Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS 'sql_cpu_utilization' 
    FROM sys.dm_os_sys_info inf CROSS JOIN (
      SELECT timestamp, CONVERT (xml, record) AS 'record'
      FROM sys.dm_os_ring_buffers 
      WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
        AND record LIKE '%<SystemHealth>%') AS t
    ORDER BY record.value('(Record/@id)[1]', 'int') DESC
  end
    
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry1 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)

  
  if (@servermajorversion >= 15)
  begin
    /* Resultset #2: sys.dm_pal_cpu_stats */
    print ''
    RAISERROR ('--sys.dm_pal_cpu_stats--', 0, 1) WITH NOWAIT
    SET @querystarttime = GETDATE()
    
    select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_cpu_stats

    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats2 qry2 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


    /* Resultset #3: sys.dm_pal_disk_stats */
    print ''
    RAISERROR ('--sys.dm_pal_disk_stats--', 0, 1) WITH NOWAIT
    SET @querystarttime = GETDATE()
    
    select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_disk_stats

    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats2 qry3 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


    /* Resultset #4: sys.dm_pal_net_stats */
    PRINT ''
    RAISERROR ('--sys.dm_pal_net_stats--', 0, 1) WITH NOWAIT;
    SET @querystarttime = GETDATE()

    select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_net_stats

    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats2 qry4 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


    /* Resultset #5: sys.dm_pal_processes */
    PRINT ''
    RAISERROR ('--sys.dm_pal_processes--', 0, 1) WITH NOWAIT;
    SET @querystarttime = GETDATE()

    select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_processes

    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats2 qry5 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)

    /* Resultset #6: sys.dm_pal_vm_stats */
    PRINT ''
    RAISERROR ('--sys.dm_pal_vm_stats--', 0, 1) WITH NOWAIT;
    SET @querystarttime = GETDATE()

    select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_vm_stats

    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats2 qry6 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)
  END
GO
  -- Main loop
  DECLARE @i int
  DECLARE @msg varchar(100)
  DECLARE @runtime datetime
  SET @i = 0
  WHILE (1=1)
  BEGIN
    SET @runtime = GETDATE()
    SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
    
    PRINT ''
    PRINT 'Start time: ' + CONVERT (varchar (30), GETDATE(), 126)
    PRINT ''
    
    -- Collect sp_perf_stats_infrequent10 every minute
    IF @i = 0
      EXEC sp_perf_stats_infrequent12 @runtime = @runtime, @firstrun = 1
    ELSE 
      EXEC sp_perf_stats_infrequent12 @runtime = @runtime
	
    WAITFOR DELAY '00:01:00'
    SET @i = @i + 1
  END
GO
