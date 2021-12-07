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


  /* Resultset #1: Server global wait stats */
  PRINT ''
  RAISERROR ('-- dm_os_wait_stats --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms, wait_type
  FROM sys.dm_os_wait_stats 
  WHERE waiting_tasks_count > 0 OR wait_time_ms > 0 OR signal_wait_time_ms > 0
  ORDER BY wait_time_ms DESC

  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry1 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #2a: dm_os_spinlock_stats */
  PRINT ''
  RAISERROR ('--  dm_os_spinlock_stats --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', collisions, spins, spins_per_collision, sleep_time, backoffs, name FROM sys.dm_os_spinlock_stats

  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry2a - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)

  
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry3 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #4: SQL processor utilization */
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
    PRINT 'DebugPrint: perfstats2 qry4 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #5: sys.dm_os_sys_info 
  ** used to determine the # of CPUs SQL is able to use at the moment */
  PRINT ''
  RAISERROR ('-- sys.dm_os_sys_info --', 0, 1) WITH NOWAIT;
  SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', * FROM sys.dm_os_sys_info


  /* Resultset #6: sys.dm_os_latch_stats */
  PRINT ''
  RAISERROR ('-- sys.dm_os_latch_stats --', 0, 1) WITH NOWAIT;
  SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', waiting_requests_count, wait_time_ms, max_wait_time_ms, latch_class
    FROM sys.dm_os_latch_stats 
	WHERE waiting_requests_count > 0 OR wait_time_ms > 0 OR max_wait_time_ms > 0
    ORDER BY wait_time_ms DESC


  /* Resultset #7: File Stats Full
  ** To conserve space, output full dbname and filenames on 1st execution only. */
  PRINT ''
  RAISERROR ('-- File Stats (full) --', 0, 1) WITH NOWAIT;
  SET @sql = 'SELECT /* sp_perf_stats_infrequent12:7 */ CONVERT (varchar(30), @runtime, 126) AS runtime, 
    fs.DbId, fs.FileId, 
    fs.IoStallMS / (fs.NumberReads + fs.NumberWrites + 1) AS AvgIOTimeMS, fs.[TimeStamp], fs.NumberReads, fs.BytesRead, 
    fs.IoStallReadMS, fs.NumberWrites, fs.BytesWritten, fs.IoStallWriteMS, fs.IoStallMS, fs.BytesOnDisk, 
    f.type, LEFT (f.type_desc, 10) AS type_desc, f.data_space_id, f.state, LEFT (f.state_desc, 15) AS state_desc, 
    f.[size], f.max_size, f.growth, f.is_sparse, f.is_percent_growth'

  IF @firstrun = 0 
    SET @sql = @sql + ', NULL AS [database], NULL AS [file]'
  ELSE
    SET @sql = @sql + ', d.name AS [database], f.physical_name AS [file]'
  SET @sql = @sql + 'FROM ::fn_virtualfilestats (null, null) fs
  INNER JOIN master.dbo.sysdatabases d ON d.dbid = fs.DbId
  INNER JOIN sys.master_files f ON fs.DbId = f.database_id AND fs.FileId = f.[file_id]
  ORDER BY AvgIOTimeMS DESC'


  SET @querystarttime = GETDATE()
  EXEC sp_executesql @sql, N'@runtime datetime', @runtime = @runtime

  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry7 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)

 
  /* Resultset #8: dm_exec_query_resource_semaphores 
  ** no reason to list columns since no long character columns */
  PRINT ''
  RAISERROR ('-- dm_exec_query_resource_semaphores --', 0, 1) WITH NOWAIT;
  SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_exec_query_resource_semaphores


  /* Resultset #9: dm_exec_query_memory_grants */
  PRINT ''
  RAISERROR ('-- dm_exec_query_memory_grants --', 0, 1) WITH NOWAIT;
  SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', session_id, request_id, scheduler_id, dop, request_time, grant_time, requested_memory_kb, granted_memory_kb, required_memory_kb, used_memory_kb, max_used_memory_kb, query_cost, timeout_sec, resource_semaphore_id, queue_id, wait_order, is_next_candidate, wait_time_ms, group_id, pool_id, is_small ideal_memory_kb, plan_handle, [sql_handle] from sys.dm_exec_query_memory_grants


  /* Resultset #10: dm_os_memory_brokers */
  PRINT ''
  RAISERROR ('-- dm_os_memory_brokers --', 0, 1) WITH NOWAIT;
  SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', pool_id, allocations_kb, allocations_kb_per_sec, predicted_allocations_kb, target_allocations_kb, future_allocations_kb, overall_limit_kb, last_notification, memory_broker_type from sys.dm_os_memory_brokers

  /* Resultset #11: dm_os_schedulers 
  ** no reason to list columns since no long character columns */
  PRINT ''
  RAISERROR ('-- dm_os_schedulers --', 0, 1) WITH NOWAIT;
  select CONVERT (varchar(30), @runtime, 126) as 'runtime', * from sys.dm_os_schedulers


  /* Resultset #12: dm_os_nodes */
  PRINT ''
  RAISERROR ('-- sys.dm_os_nodes --', 0, 1) WITH NOWAIT;
  SELECT CONVERT (varchar(30), @runtime, 126) as 'runtime', node_id, memory_object_address, memory_clerk_address, io_completion_worker_address, memory_node_id, cpu_affinity_mask, online_scheduler_count, idle_scheduler_count, active_worker_count, avg_load_balance, timer_task_affinity_mask, permanent_task_affinity_mask, resource_monitor_state, online_scheduler_mask, processor_group, node_state_desc FROM sys.dm_os_nodes


  /* Resultset #13: dm_os_memory_nodes 
  ** no reason to list columns since no long character columns */
  PRINT ''
  RAISERROR ('-- sys.dm_os_memory_nodes --', 0, 1) WITH NOWAIT;
  SELECT CONVERT (varchar(30), @runtime, 126) as 'runtime',* FROM sys.dm_os_memory_nodes

  --/* Resultset #14: Lock summary */
  --PRINT ''
  --RAISERROR ('-- Lock summary --', 0, 1) WITH NOWAIT;
  --SET @querystarttime = GETDATE()

  --select CONVERT (varchar(30), @runtime, 126) as 'runtime', * from 
  --  (select  count (*) as 'LockCount', Resource_database_id, LEFT(resource_type,15) as 'resource_type', LEFT(request_mode,20) as 'request_mode', request_status from sys.dm_tran_locks 
  --    group by  Resource_database_id, resource_type, request_mode, request_status ) t

  --SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  --IF @queryduration > @qrydurationwarnthreshold
  --  PRINT 'DebugPrint: perfstats2 qry14 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  --/* Resultset #15: Thread Statistics */
  --PRINT ''
  --RAISERROR ('-- Thread Statistics --', 0, 1) WITH NOWAIT
  --SET @querystarttime = GETDATE()

  --select CONVERT (varchar(30), @runtime, 126) as 'runtime', th.os_thread_id, ta.scheduler_id, ta.session_id, ta.request_id, req.command, usermode_time, kernel_time, req.cpu_time as 'req_cpu_time',  req.logical_reads,req.total_elapsed_time,
  --    REPLACE (REPLACE (SUBSTRING (sql.[text], CHARINDEX ('CREATE ', CONVERT (nvarchar(512), SUBSTRING (sql.[text], 1, 1000)) COLLATE Latin1_General_BIN), 50) COLLATE Latin1_General_BIN, CHAR(10), ' '), CHAR(13), ' ') as 'QueryText'
  --  from sys.dm_os_threads th join sys.dm_os_tasks ta on th.worker_address = ta.worker_address
  --    left outer join sys.dm_exec_requests req on ta.session_id = req.session_id and ta.request_id = req.request_id
  --    outer apply sys.dm_exec_sql_text (req.sql_handle) sql

  --SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  --IF @queryduration > @qrydurationwarnthreshold
  --  PRINT 'DebugPrint: perfstats2 qry15 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #16: dm_db_file_space_usage 
  ** must be run from tempdb */
  PRINT ''
  RAISERROR ('-- dm_db_file_space_usage --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', * FROM sys.dm_db_file_space_usage

  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry16 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #17: dm_exec_cursors(0) */
  PRINT ''
  RAISERROR ('-- dm_exec_cursors(0) --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', COUNT(*) AS 'count', SUM(CONVERT(INT,is_open)) AS 'open count', MIN(creation_time) AS 'oldest create',[properties]
    FROM sys.dm_exec_cursors(0)
    GROUP BY [properties]

  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry17 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #18:  dm_os_ring_buffers for connectivity*/
  PRINT ''
  RAISERROR ('-- dm_os_ring_buffers --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()
  declare @ts bigint
  declare @timediff bigint = 1000*60*2 --2 min in milliseconds
  select @ts = ms_ticks from sys.dm_os_sys_info
  if @ts < @timediff
  begin
	  set @ts = 0
  end
  else
  begin
	  set @ts = @ts - @timediff
  end

  SET @sql = 'SELECT /*sp_perf_stats_infrequent12:18*/ CONVERT (varchar(30), @runtime, 126) AS runtime, 
      CONVERT (varchar(23), DATEADD (ms, -1 * (inf.ms_ticks - rb.[timestamp]), GETDATE()), 126) AS EventTime, rb.[record]
    FROM sys.dm_os_sys_info inf 
      CROSS JOIN 
      (
        SELECT [timestamp], [record] 
          FROM sys.dm_os_ring_buffers 
          WHERE ring_buffer_type in (''RING_BUFFER_CONNECTIVITY'',''RING_BUFFER_SECURITY_ERROR'',''RING_BUFFER_SECURITY_CACHE'')'
  IF @firstrun = 0
    SET @sql = @sql + '            AND [timestamp] > @ts'
  SET @sql = @sql + '      ) as rb
    ORDER BY rb.[timestamp] DESC'

  EXEC sp_executesql @sql, N'@runtime datetime, @ts bigint', @runtime = @runtime, @ts = @ts

  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry18 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  --/* Resultset #19: Plan Cache Stats */
  --PRINT ''
  --RAISERROR ('-- Plan Cache Stats --', 0, 1) WITH NOWAIT;
  --SET @querystarttime = GETDATE()

  --SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime',*  from 
  --  (select  objtype, sum(cast(size_in_bytes as bigint) /cast(1024.00 as decimal(38,2)) /1024.00) 'Cache_Size_MB' , count_big (*) 'Entry_Count', isnull(db_name(cast (value as int)),'mssqlsystemresource') 'db name'
	 -- from  sys.dm_exec_cached_plans AS p CROSS APPLY sys.dm_exec_plan_attributes ( plan_handle ) as t 
  --    where attribute='dbid'
  --    group by  isnull(db_name(cast (value as int)),'mssqlsystemresource'), objtype )  t
  --  order by Entry_Count desc

  --SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  --IF @queryduration > @qrydurationwarnthreshold
  --  PRINT 'DebugPrint: perfstats2 qry19 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #20: System Requests */
  PRINT ''
  RAISERROR ('-- System Requests --', 0, 1) WITH NOWAIT
  SET @querystarttime = GETDATE()
  
  select /*qry20*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', tr.os_thread_id, req.* 
    from sys.dm_exec_requests req 
	  join sys.dm_os_workers wrk  on req.task_address = wrk.task_address and req.connection_id is null
      join sys.dm_os_threads tr on tr.worker_address=wrk.worker_address


	  RAISERROR (' ', 0, 1) WITH NOWAIT;
  --SET @rowcount = @@ROWCOUNT
  --SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  --IF @queryduration > @qrydurationwarnthreshold
  --  PRINT 'DebugPrint: perfstats2 qry20 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)



  --/* Raise a diagnostic message if we use more CPU than normal (a typical execution uses <200ms) */
  --DECLARE @cpu_time bigint, @elapsed_time bigint
  --SELECT @cpu_time = cpu_time - @cpu_time_start, @elapsed_time = total_elapsed_time - @elapsed_time_start FROM sys.dm_exec_sessions WHERE session_id = @@SPID
  --IF (@elapsed_time > 3000 OR @cpu_time > 1000) BEGIN
  --  PRINT ''
  --  PRINT 'DebugPrint: perfstats2 tot - ' + CONVERT (varchar, @elapsed_time) + 'ms elapsed, ' + CONVERT (varchar, @cpu_time) + 'ms cpu' + CHAR(13) + CHAR(10)  
  --END

  --RAISERROR ('', 0, 1) WITH NOWAIT;

GO



--DECLARE @servermajorversion int
---- SERVERPROPERTY ('ProductVersion') returns e.g. "9.00.2198.00" --> 9
--SET @servermajorversion = REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')
--IF (@servermajorversion < 12)
--  PRINT 'This script only runs on SQL Server 2014 and later. Exiting.'
--ELSE BEGIN
  -- Main loop
  DECLARE @i int
  DECLARE @msg varchar(100)
  DECLARE @runtime datetime
  SET @i = 0
  WHILE (1=1)
  BEGIN
    SET @runtime = GETDATE()
    SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
    
    -- Collect sp_perf_stats_infrequent10 every minute
    IF @i = 0
      EXEC sp_perf_stats_infrequent12 @runtime = @runtime, @firstrun = 1
    ELSE 
      EXEC sp_perf_stats_infrequent12 @runtime = @runtime
	
    WAITFOR DELAY '00:01:00'
    SET @i = @i + 1
  END

GO
