
/*******************************************************************
perf stats


********************************************************************/
USE tempdb
GO
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET NUMERIC_ROUNDABORT OFF
GO

go
IF OBJECT_ID ('sp_perf_stats','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats
GO
CREATE PROCEDURE sp_perf_stats @appname sysname='PSSDIAG', @runtime datetime, @prevruntime datetime, @IsLite bit=0 
AS 
 SET NOCOUNT ON
  DECLARE @msg varchar(100)
  DECLARE @querystarttime datetime
  DECLARE @queryduration int
  DECLARE @qrydurationwarnthreshold int
  DECLARE @servermajorversion int
  DECLARE @cpu_time_start bigint, @elapsed_time_start bigint
  DECLARE @sql nvarchar(max)
  DECLARE @cte nvarchar(max)
  DECLARE @rowcount bigint

  SELECT @cpu_time_start = cpu_time, @elapsed_time_start = total_elapsed_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID

  IF OBJECT_ID ('tempdb.dbo.#tmp_requests') IS NOT NULL DROP TABLE #tmp_requests
  IF OBJECT_ID ('tempdb.dbo.#tmp_requests2') IS NOT NULL DROP TABLE #tmp_requests2
  
  IF @runtime IS NULL 
  BEGIN 
    SET @runtime = GETDATE()
    SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
    RAISERROR (@msg, 0, 1) WITH NOWAIT
  END

RAISERROR (' ', 0, 1) WITH NOWAIT
RAISERROR ('-- sys.dm_tran_session_transactions (DTC ONLY) --', 0, 1) WITH NOWAIT
select @runtime, * from sys.dm_tran_session_transactions where is_local = 0
RAISERROR (' ', 0, 1) WITH NOWAIT



RAISERROR (' ', 0, 1) WITH NOWAIT
RAISERROR ('-- sys.dm_tran_active_transactions (DTC ONLY) --', 0, 1) WITH NOWAIT
select @runtime, * from sys.dm_tran_active_transactions where transaction_type = 4
RAISERROR (' ', 0, 1) WITH NOWAIT

  SET @qrydurationwarnthreshold = 500
  
  -- SERVERPROPERTY ('ProductVersion') returns e.g. "9.00.2198.00" --> 9
  SET @servermajorversion = REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')

  RAISERROR (@msg, 0, 1) WITH NOWAIT

  SET @querystarttime = GETDATE()

  SELECT  blocking_session_id into #blockingSessions FROM sys.dm_exec_requests WHERE blocking_session_id != 0
  create index ix_blockingSessions_1 on #blockingSessions (blocking_session_id)

  select * into #dm_exec_sessions_raw from sys.dm_exec_sessions

  create index ix_dm_exec_sessions on #dm_exec_sessions_raw (session_id)

  create index ix_dm_exec_sessions_is_user_process on #dm_exec_sessions_raw (is_user_process)

  select * into #requests_raw from   sys.dm_exec_requests
  
  create index ix_requests_raw_session_id on #requests_raw (session_id)
  create index ix_requests_raw_request_id on #requests_raw (request_id)
  create index ix_requests_raw_status on #requests_raw (status)
  create index ix_requests_raw_wait_type on #requests_raw (wait_type)
  
  select * into #dm_os_tasks from   sys.dm_os_tasks
  create index ix_dm_os_tasks_session_id on #dm_os_tasks (session_id)
  create index ix_dm_os_tasks_request_id on #dm_os_tasks (request_id)

  select * into #dm_exec_connections from   sys.dm_exec_connections
  create index ix_dm_exec_connections_session_id on #dm_exec_connections (session_id)

  select * into #dm_tran_active_transactions from   sys.dm_tran_active_transactions 
  create index ix_dm_tran_active_transactions_transaction_id on #dm_tran_active_transactions(transaction_id)

  select * into #dm_tran_session_transactions from  sys.dm_tran_session_transactions

  create index  ix_dm_tran_session_transactions_session_id on #dm_tran_session_transactions (session_id)

  select * into #dm_os_waiting_tasks  from  sys.dm_os_waiting_tasks
  create index ix_dm_os_waiting_tasks_waiting_task_address on #dm_os_waiting_tasks(waiting_task_address)

  select * into #sysprocesses from master.dbo.sysprocesses 
  create index ix_sysprocesses_spid on #sysprocesses (spid)


  SELECT
    sess.session_id, req.request_id, tasks.exec_context_id AS 'ecid', tasks.task_address, req.blocking_session_id, LEFT (tasks.task_state, 15) AS 'task_state', 
    tasks.scheduler_id, LEFT (ISNULL (req.wait_type, ''), 50) AS 'wait_type', LEFT (ISNULL (req.wait_resource, ''), 40) AS 'wait_resource', 
    LEFT (req.last_wait_type, 50) AS 'last_wait_type', 
    /* sysprocesses is the only way to get open_tran count for sessions w/o an active request (SQLBUD #487091) */
    CASE 
      WHEN req.open_transaction_count IS NOT NULL THEN req.open_transaction_count 
      ELSE (SELECT open_tran FROM #sysprocesses sysproc WHERE sess.session_id = sysproc.spid) 
    END AS open_trans, 
    LEFT (CASE COALESCE(req.transaction_isolation_level, sess.transaction_isolation_level)
      WHEN 0 THEN '0-Read Committed' 
      WHEN 1 THEN '1-Read Uncommitted (NOLOCK)' 
      WHEN 2 THEN '2-Read Committed' 
      WHEN 3 THEN '3-Repeatable Read' 
      WHEN 4 THEN '4-Serializable' 
      WHEN 5 THEN '5-Snapshot' 
      ELSE CONVERT (varchar(30), req.transaction_isolation_level) + '-UNKNOWN' 
    END, 30) AS transaction_isolation_level, 
    sess.is_user_process, req.cpu_time AS 'request_cpu_time', 
    req.logical_reads request_logical_reads,
    req.reads request_reads,
     req.writes request_writes,
    sess.memory_usage, sess.cpu_time AS 'session_cpu_time', sess.reads AS 'session_reads', sess.writes AS 'session_writes', sess.logical_reads AS 'session_logical_reads', 
    sess.total_scheduled_time, sess.total_elapsed_time, sess.last_request_start_time, sess.last_request_end_time, sess.row_count AS session_row_count, 
    sess.prev_error, req.open_resultset_count AS open_resultsets, req.total_elapsed_time AS request_total_elapsed_time, 
    CONVERT (decimal(5,2), req.percent_complete) AS percent_complete, req.estimated_completion_time AS est_completion_time, req.transaction_id, 
    req.start_time AS request_start_time, LEFT (req.status, 15) AS request_status, req.command, req.plan_handle, req.sql_handle, req.statement_start_offset, 
    req.statement_end_offset, req.database_id, req.[user_id], req.executing_managed_code, tasks.pending_io_count, sess.login_time, 
    LEFT (sess.[host_name], 20) AS [host_name], LEFT (ISNULL (sess.program_name, ''), 50) AS program_name, ISNULL (sess.host_process_id, 0) AS 'host_process_id', 
    ISNULL (sess.client_version, 0) AS 'client_version', LEFT (ISNULL (sess.client_interface_name, ''), 30) AS 'client_interface_name', 
    LEFT (ISNULL (sess.login_name, ''), 30) AS 'login_name', LEFT (ISNULL (sess.nt_domain, ''), 30) AS 'nt_domain', LEFT (ISNULL (sess.nt_user_name, ''), 20) AS 'nt_user_name', 
    ISNULL (conn.net_packet_size, 0) AS 'net_packet_size', LEFT (ISNULL (conn.client_net_address, ''), 20) AS 'client_net_address', conn.most_recent_sql_handle, 
    LEFT (sess.status, 15) AS 'session_status',
    /* sys.dm_os_workers and sys.dm_os_threads removed due to perf impact, no predicate pushdown (SQLBU #488971) */
    --  workers.is_preemptive,
    --  workers.is_sick, 
    --  workers.exception_num AS last_worker_exception, 
    --  convert (varchar (20), master.dbo.fn_varbintohexstr (workers.exception_address)) AS last_exception_address
    --  threads.os_thread_id 
    sess.group_id, req.query_hash, req.query_plan_hash  
  INTO #tmp_requests
  FROM #dm_exec_sessions_raw sess 
  /* Join hints are required here to work around bad QO join order/type decisions (ultimately by-design, caused by the lack of accurate DMV card estimates) */
  LEFT OUTER  JOIN #requests_raw  req  ON sess.session_id = req.session_id
  LEFT OUTER  JOIN #dm_os_tasks tasks ON tasks.session_id = sess.session_id AND tasks.request_id = req.request_id 
  /* The following two DMVs removed due to perf impact, no predicate pushdown (SQLBU #488971) */
  --  LEFT OUTER MERGE JOIN sys.dm_os_workers workers ON tasks.worker_address = workers.worker_address
  --  LEFT OUTER MERGE JOIN sys.dm_os_threads threads ON workers.thread_address = threads.thread_address
  LEFT OUTER JOIN #dm_exec_connections conn on conn.session_id = sess.session_id
  WHERE 
    /* Get execution state for all active queries... */
    (req.session_id IS NOT NULL AND (sess.is_user_process = 1 OR req.status COLLATE Latin1_General_BIN NOT IN ('background', 'sleeping')))
    /* ... and also any head blockers, even though they may not be running a query at the moment. */
    OR (sess.session_id IN (SELECT blocking_session_id FROM #blockingSessions))
  /* redundant due to the use of join hints, but added here to suppress warning message */
  OPTION (maxdop 1)  

  create index ix_temp_request_session_id on #tmp_requests(session_id) 
  create index ix_temp_request_transaction_id on #tmp_requests(transaction_id) 
  create index ix_temp_request_task_address on #tmp_requests(task_address)  


  SET @rowcount = @@ROWCOUNT
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats qry0 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

  IF NOT EXISTS (SELECT * FROM #tmp_requests WHERE session_id <> @@SPID AND ISNULL (host_name, '') != @appname) BEGIN
    PRINT 'No active queries'
  END
  ELSE BEGIN
    -- There are active queries (other than this one). 
    -- This query could be collapsed into the query above.  It is broken out here to avoid an excessively 
    -- large memory grant due to poor cardinality estimates (see previous bugs -- ultimate cause is the 
    -- lack of good stats for many DMVs). 
    SET @querystarttime = GETDATE()
    SELECT 
      IDENTITY (int,1,1) AS tmprownum, 
      r.session_id, r.request_id, r.ecid, r.blocking_session_id, ISNULL (waits.blocking_exec_context_id, 0) AS blocking_ecid, 
      r.task_state, waits.wait_type, ISNULL (waits.wait_duration_ms, 0) AS wait_duration_ms, r.wait_resource, 
      LEFT (ISNULL (waits.resource_description, ''), 140) AS resource_description, r.last_wait_type, r.open_trans, 
      r.transaction_isolation_level, r.is_user_process, r.request_cpu_time, r.request_logical_reads, r.request_reads, 
      r.request_writes, r.memory_usage, r.session_cpu_time, r.session_reads, r.session_writes, r.session_logical_reads, 
      r.total_scheduled_time, r.total_elapsed_time, r.last_request_start_time, r.last_request_end_time, r.session_row_count, 
      r.prev_error, r.open_resultsets, r.request_total_elapsed_time, r.percent_complete, r.est_completion_time, 
      -- r.tran_name, r.transaction_begin_time, r.tran_type, r.tran_state, 
      LEFT (COALESCE (reqtrans.name, sesstrans.name, ''), 24) AS tran_name, 
      COALESCE (reqtrans.transaction_begin_time, sesstrans.transaction_begin_time) AS transaction_begin_time, 
      LEFT (CASE COALESCE (reqtrans.transaction_type, sesstrans.transaction_type)
        WHEN 1 THEN '1-Read/write'
        WHEN 2 THEN '2-Read only'
        WHEN 3 THEN '3-System'
        WHEN 4 THEN '4-Distributed'
        ELSE CONVERT (varchar(30), COALESCE (reqtrans.transaction_type, sesstrans.transaction_type)) + '-UNKNOWN' 
      END, 15) AS tran_type, 
      LEFT (CASE COALESCE (reqtrans.transaction_state, sesstrans.transaction_state)
        WHEN 0 THEN '0-Initializing'
        WHEN 1 THEN '1-Initialized'
        WHEN 2 THEN '2-Active'
        WHEN 3 THEN '3-Ended'
        WHEN 4 THEN '4-Preparing'
        WHEN 5 THEN '5-Prepared'
        WHEN 6 THEN '6-Committed'
        WHEN 7 THEN '7-Rolling back'
        WHEN 8 THEN '8-Rolled back'
        ELSE CONVERT (varchar(30), COALESCE (reqtrans.transaction_state, sesstrans.transaction_state)) + '-UNKNOWN'
      END, 15) AS tran_state, 
      r.request_start_time, r.request_status, r.command, r.plan_handle, r.[sql_handle], r.statement_start_offset, 
      r.statement_end_offset, r.database_id, r.[user_id], r.executing_managed_code, r.pending_io_count, r.login_time, 
      r.[host_name], r.[program_name], r.host_process_id, r.client_version, r.client_interface_name, r.login_name, r.nt_domain, 
      r.nt_user_name, r.net_packet_size, r.client_net_address, r.most_recent_sql_handle, r.session_status, r.scheduler_id,
      -- r.is_preemptive, r.is_sick, r.last_worker_exception, r.last_exception_address, 
      -- r.os_thread_id
      r.group_id, r.query_hash, r.query_plan_hash
    INTO #tmp_requests2
    FROM #tmp_requests r
    /* Join hints are required here to work around bad QO join order/type decisions (ultimately by-design, caused by the lack of accurate DMV card estimates) */
    LEFT OUTER MERGE JOIN #dm_tran_active_transactions reqtrans ON r.transaction_id = reqtrans.transaction_id
    
    LEFT OUTER MERGE JOIN #dm_tran_session_transactions sessions_transactions on sessions_transactions.session_id = r.session_id
    
    LEFT OUTER MERGE JOIN #dm_tran_active_transactions sesstrans ON sesstrans.transaction_id = sessions_transactions.transaction_id
    
    LEFT OUTER MERGE JOIN #dm_os_waiting_tasks waits ON waits.waiting_task_address = r.task_address 
    ORDER BY r.session_id, blocking_ecid
    /* redundant due to the use of join hints, but added here to suppress warning message */
    OPTION (maxdop 1)  
    SET @rowcount = @@ROWCOUNT
    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats qry0a - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

    /* This index typically takes <10ms to create, and drops the head blocker summary query cost from ~250ms CPU down to ~20ms. */
    CREATE NONCLUSTERED INDEX idx1 ON #tmp_requests2 (blocking_session_id, session_id, wait_type, wait_duration_ms)

    /* Output Resultset #1: summary of all active requests (and head blockers) 
    ** Dynamic (but explicitly parameterized) SQL used here to allow for (optional) direct-to-database data collection 
    ** without unnecessary code duplication. */
    RAISERROR ('-- requests --', 0, 1) WITH NOWAIT
    SET @querystarttime = GETDATE()

    SELECT TOP 10000 CONVERT (varchar(30), @runtime, 126) AS 'runtime', 
      session_id, request_id, ecid, blocking_session_id, blocking_ecid, task_state, 
      wait_type, wait_duration_ms, wait_resource, resource_description, last_wait_type, 
      open_trans, transaction_isolation_level, is_user_process, 
      request_cpu_time, request_logical_reads, request_reads, request_writes, memory_usage, 
      session_cpu_time, session_reads, session_writes, session_logical_reads, total_scheduled_time, 
      total_elapsed_time, CONVERT (varchar(30), last_request_start_time, 126) AS 'last_request_start_time', 
      CONVERT (varchar(30), last_request_end_time, 126) AS 'last_request_end_time', session_row_count, 
      prev_error, open_resultsets, request_total_elapsed_time, percent_complete, 
      est_completion_time, tran_name, 
      CONVERT (varchar(30), transaction_begin_time, 126) AS 'transaction_begin_time', tran_type, 
      tran_state, CONVERT (varchar, request_start_time, 126) AS request_start_time, request_status, 
      command, statement_start_offset, statement_end_offset, database_id, [user_id], 
      executing_managed_code, pending_io_count, CONVERT (varchar(30), login_time, 126) AS 'login_time', 
      [host_name], [program_name], host_process_id, client_version, client_interface_name, login_name, 
      nt_domain, nt_user_name, net_packet_size, client_net_address, session_status, 
      scheduler_id,
      -- is_preemptive, is_sick, last_worker_exception, last_exception_address
      -- os_thread_id
      group_id, query_hash, query_plan_hash, plan_handle      
    FROM #tmp_requests2 r
    WHERE ISNULL ([host_name], '''') != @appname AND r.session_id != @@SPID 
      /* One EC can have multiple waits in sys.dm_os_waiting_tasks (e.g. parent thread waiting on multiple children, for example 
      ** for parallel create index; or mem grant waits for RES_SEM_FOR_QRY_COMPILE).  This will result in the same EC being listed 
      ** multiple times in the request table, which is counterintuitive for most people.  Instead of showing all wait relationships, 
      ** for each EC we will report the wait relationship that has the longest wait time.  (If there are multiple relationships with 
      ** the same wait time, blocker spid/ecid is used to choose one of them.)  If it were not for , we would do this 
      ** exclusion in the previous query to avoid storing data that will ultimately be filtered out. */
      AND NOT EXISTS 
        (SELECT * FROM #tmp_requests2 r2 
         WHERE r.session_id = r2.session_id AND r.request_id = r2.request_id AND r.ecid = r2.ecid AND r.wait_type = r2.wait_type 
           AND (r2.wait_duration_ms > r.wait_duration_ms OR (r2.wait_duration_ms = r.wait_duration_ms AND r2.tmprownum > r.tmprownum)))
    
	RAISERROR (' ', 0, 1) WITH NOWAIT
    
    SET @rowcount = @@ROWCOUNT
    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats qry1 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

    /* Resultset #2: Head blocker summary 
    ** Intra-query blocking relationships (parallel query waits) aren't "true" blocking problems that we should report on here. */
    IF NOT EXISTS (SELECT * FROM #tmp_requests2 WHERE blocking_session_id != 0 AND wait_type NOT IN ('WAITFOR', 'EXCHANGE', 'CXPACKET') AND wait_duration_ms > 0) 
    BEGIN 
      PRINT ''
      PRINT '-- No blocking detected --'
      PRINT ''
    END
    ELSE BEGIN
      PRINT ''
      PRINT '-----------------------'
      PRINT '-- BLOCKING DETECTED --'
      PRINT ''
      RAISERROR ('-- headblockersummary --', 0, 1) WITH NOWAIT;
      /* We need stats like the number of spids blocked, max waittime, etc, for each head blocker.  Use a recursive CTE to 
      ** walk the blocking hierarchy. Again, explicitly parameterized dynamic SQL used to allow optional collection direct  
      ** to a database. */
      SET @querystarttime = GETDATE();
      
      WITH BlockingHierarchy (head_blocker_session_id, session_id, blocking_session_id, wait_type, wait_duration_ms, 
        wait_resource, statement_start_offset, statement_end_offset, plan_handle, sql_handle, most_recent_sql_handle, [Level]) 
      AS (
        SELECT head.session_id AS head_blocker_session_id, head.session_id AS session_id, head.blocking_session_id, 
          head.wait_type, head.wait_duration_ms, head.wait_resource, head.statement_start_offset, head.statement_end_offset, 
          head.plan_handle, head.sql_handle, head.most_recent_sql_handle, 0 AS [Level]
        FROM #tmp_requests2 head
        WHERE (head.blocking_session_id IS NULL OR head.blocking_session_id = 0) 
          AND head.session_id IN (SELECT DISTINCT blocking_session_id FROM #tmp_requests2 WHERE blocking_session_id != 0) 
        UNION ALL 
        SELECT h.head_blocker_session_id, blocked.session_id, blocked.blocking_session_id, blocked.wait_type, 
          blocked.wait_duration_ms, blocked.wait_resource, h.statement_start_offset, h.statement_end_offset, 
          h.plan_handle, h.sql_handle, h.most_recent_sql_handle, [Level] + 1
        FROM #tmp_requests2 blocked
        INNER JOIN BlockingHierarchy AS h ON h.session_id = blocked.blocking_session_id and h.session_id!=blocked.session_id --avoid infinite recursion for latch type of blocknig
        WHERE h.wait_type COLLATE Latin1_General_BIN NOT IN ('EXCHANGE', 'CXPACKET') or h.wait_type is null
      )
      SELECT CONVERT (varchar(30), @runtime, 126) AS 'runtime', 
        head_blocker_session_id, COUNT(*) AS 'blocked_task_count', SUM (ISNULL (wait_duration_ms, 0)) AS 'tot_wait_duration_ms', 
        LEFT (CASE 
          WHEN wait_type LIKE 'LCK%' COLLATE Latin1_General_BIN AND wait_resource LIKE '%\[COMPILE\]%' ESCAPE '\' COLLATE Latin1_General_BIN 
            THEN 'COMPILE (' + ISNULL (wait_resource, '') + ')' 
          WHEN wait_type LIKE 'LCK%' COLLATE Latin1_General_BIN THEN 'LOCK BLOCKING' 
          WHEN wait_type LIKE 'PAGELATCH%' COLLATE Latin1_General_BIN THEN 'PAGELATCH_* WAITS' 
          WHEN wait_type LIKE 'PAGEIOLATCH%' COLLATE Latin1_General_BIN THEN 'PAGEIOLATCH_* WAITS' 
          ELSE wait_type
        END, 40) AS 'blocking_resource_wait_type', AVG (ISNULL (wait_duration_ms, 0)) AS 'avg_wait_duration_ms', MAX(wait_duration_ms) AS 'max_wait_duration_ms', 
        MAX ([Level]) AS 'max_blocking_chain_depth', 
        MAX (ISNULL (CONVERT (nvarchar(60), CASE 
          WHEN sql.objectid IS NULL THEN NULL 
          ELSE REPLACE (REPLACE (SUBSTRING (sql.[text], CHARINDEX ('CREATE ', CONVERT (nvarchar(512), SUBSTRING (sql.[text], 1, 1000)) COLLATE Latin1_General_BIN), 50) COLLATE Latin1_General_BIN, CHAR(10), ' '), CHAR(13), ' ')
        END), '')) AS 'head_blocker_proc_name', 
        MAX (ISNULL (sql.objectid, 0)) AS 'head_blocker_proc_objid', MAX (ISNULL (CONVERT (nvarchar(1000), REPLACE (REPLACE (SUBSTRING (sql.[text], ISNULL (statement_start_offset, 0)/2 + 1, 
          CASE WHEN ISNULL (statement_end_offset, 8192) <= 0 THEN 8192 
          ELSE ISNULL (statement_end_offset, 8192)/2 - ISNULL (statement_start_offset, 0)/2 END + 1) COLLATE Latin1_General_BIN, 
        CHAR(13), ' '), CHAR(10), ' ')), '')) AS 'stmt_text', 
        CONVERT (varbinary (64), MAX (ISNULL (plan_handle, 0x))) AS 'head_blocker_plan_handle'
      FROM BlockingHierarchy
      OUTER APPLY sys.dm_exec_sql_text (ISNULL ([sql_handle], most_recent_sql_handle)) AS sql
      WHERE blocking_session_id != 0 AND [Level] > 0
      GROUP BY head_blocker_session_id, 
        LEFT (CASE 
          WHEN wait_type LIKE 'LCK%' COLLATE Latin1_General_BIN AND wait_resource LIKE '%\[COMPILE\]%' ESCAPE '\' COLLATE Latin1_General_BIN 
            THEN 'COMPILE (' + ISNULL (wait_resource, '') + ')' 
          WHEN wait_type LIKE 'LCK%' COLLATE Latin1_General_BIN THEN 'LOCK BLOCKING' 
          WHEN wait_type LIKE 'PAGELATCH%' COLLATE Latin1_General_BIN THEN 'PAGELATCH_* WAITS' 
          WHEN wait_type LIKE 'PAGEIOLATCH%' COLLATE Latin1_General_BIN THEN 'PAGEIOLATCH_* WAITS' 
          ELSE wait_type
        END, 40) 
      ORDER BY SUM (wait_duration_ms) DESC;
      
	  RAISERROR (' ', 0, 1) WITH NOWAIT

      
      SET @rowcount = @@ROWCOUNT
      SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
      IF @queryduration > @qrydurationwarnthreshold
        PRINT 'DebugPrint: perfstats qry2 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)
    END

    /* Resultset #3: inputbuffers and query stats for "expensive" queries, head blockers, and "first-tier" blocked spids */
    PRINT ''
    RAISERROR ('-- notableactivequeries --', 0, 1) WITH NOWAIT
    SET @querystarttime = GETDATE()

    SELECT DISTINCT TOP 500 
      CONVERT (varchar(30), @runtime, 126) AS 'runtime', r.session_id AS session_id, r.request_id AS request_id, stat.execution_count AS 'plan_total_exec_count', 
      stat.total_worker_time/1000 AS 'plan_total_cpu_ms', stat.total_elapsed_time/1000 AS 'plan_total_duration_ms', stat.total_physical_reads AS 'plan_total_physical_reads', 
      stat.total_logical_writes AS 'plan_total_logical_writes', stat.total_logical_reads AS 'plan_total_logical_reads', 
      LEFT (CASE 
        WHEN pa.value=32767 THEN 'ResourceDb'
        ELSE ISNULL (DB_NAME (CONVERT (sysname, pa.value)), CONVERT (sysname, pa.value))
      END, 40) AS 'dbname', 
      sql.objectid AS 'objectid', 
      CONVERT (nvarchar(60), CASE 
        WHEN sql.objectid IS NULL THEN NULL 
        ELSE REPLACE (REPLACE (SUBSTRING (sql.[text] COLLATE Latin1_General_BIN, CHARINDEX ('CREATE ', SUBSTRING (sql.[text] COLLATE Latin1_General_BIN, 1, 1000)), 50), CHAR(10), ' '), CHAR(13), ' ')
      END) AS procname, 
      CONVERT (nvarchar(300), REPLACE (REPLACE (CONVERT (nvarchar(300), SUBSTRING (sql.[text], ISNULL (r.statement_start_offset, 0)/2 + 1, 
          CASE WHEN ISNULL (r.statement_end_offset, 8192) <= 0 THEN 8192 
          ELSE ISNULL (r.statement_end_offset, 8192)/2 - ISNULL (r.statement_start_offset, 0)/2 END + 1)) COLLATE Latin1_General_BIN, 
        CHAR(13), ' '), CHAR(10), ' ')) AS 'stmt_text', 
      CONVERT (varbinary (64), (r.plan_handle)) AS 'plan_handle',
      group_id
    FROM #tmp_requests2 r
    LEFT OUTER JOIN sys.dm_exec_query_stats stat ON r.plan_handle = stat.plan_handle AND stat.statement_start_offset = r.statement_start_offset
    OUTER APPLY sys.dm_exec_plan_attributes (r.plan_handle) pa
    OUTER APPLY sys.dm_exec_sql_text (ISNULL (r.[sql_handle], r.most_recent_sql_handle)) AS sql
    WHERE (pa.attribute = 'dbid' COLLATE Latin1_General_BIN OR pa.attribute IS NULL) AND ISNULL (host_name, '') != @appname AND r.session_id != @@SPID 
      AND ( 
        /* We do not want to pull inputbuffers for everyone. The conditions below determine which ones we will fetch. */
        (r.session_id IN (SELECT blocking_session_id FROM #tmp_requests2 WHERE blocking_session_id != 0)) -- head blockers
        OR (r.blocking_session_id IN (SELECT blocking_session_id FROM #tmp_requests2 WHERE blocking_session_id != 0)) -- "first-tier" blocked requests
        OR (LTRIM (r.wait_type) <> '''' OR r.wait_duration_ms > 500) -- waiting for some resource
        OR (r.open_trans > 5) -- possible orphaned transaction
        OR (r.request_total_elapsed_time > 25000) -- long-running query
        OR (r.request_logical_reads > 1000000 OR r.request_cpu_time > 3000) -- expensive (CPU) query
        OR (r.request_reads + r.request_writes > 5000 OR r.pending_io_count > 400) -- expensive (I/O) query
        OR (r.memory_usage > 25600) -- expensive (memory > 200MB) query
        -- OR (r.is_sick > 0) -- spinloop
      )
    ORDER BY stat.total_worker_time/1000 DESC

	RAISERROR (' ', 0, 1) WITH NOWAIT

    SET @rowcount = @@ROWCOUNT
    SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
    IF @rowcount >= 500 PRINT 'WARNING: notableactivequeries output artificially limited to 500 rows'
    IF @queryduration > @qrydurationwarnthreshold
      PRINT 'DebugPrint: perfstats qry3 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

    IF '%runmode%' = 'REALTIME' BEGIN 
      -- In near-realtime/direct-to-database mode, we have to maintain tbl_BLOCKING_CHAINS on-the-fly
      -- 1) Insert new blocking chains
	  RAISERROR ('', 0, 1) WITH NOWAIT
      INSERT INTO tbl_BLOCKING_CHAINS (first_rownum, last_rownum, num_snapshots, blocking_start, blocking_end, head_blocker_session_id, 
        blocking_wait_type, max_blocked_task_count, max_total_wait_duration_ms, avg_wait_duration_ms, max_wait_duration_ms, 
        max_blocking_chain_depth, head_blocker_session_id_orig)
      SELECT rownum, NULL, 1, runtime, NULL, 
        CASE WHEN blocking_resource_wait_type LIKE 'COMPILE%' THEN 'COMPILE BLOCKING' ELSE head_blocker_session_id END AS head_blocker_session_id, 
        blocking_resource_wait_type, blocked_task_count, tot_wait_duration_ms, avg_wait_duration_ms, max_wait_duration_ms, 
        max_blocking_chain_depth, head_blocker_session_id
      FROM tbl_HEADBLOCKERSUMMARY b1 
      WHERE b1.runtime = @runtime AND NOT EXISTS (
        SELECT * FROM tbl_BLOCKING_CHAINS b2  
        WHERE b2.blocking_end IS NULL  -- end-of-blocking has not been detected yet
          AND b2.head_blocker_session_id = CASE WHEN blocking_resource_wait_type LIKE 'COMPILE%' THEN 'COMPILE BLOCKING' ELSE head_blocker_session_id END -- same head blocker
          AND b2.blocking_wait_type = b1.blocking_resource_wait_type -- same type of blocking
      )
      PRINT 'Inserted ' + CONVERT (varchar, @@ROWCOUNT) + ' new blocking chains...'

      -- 2) Update statistics for in-progress blocking incidents
      UPDATE tbl_BLOCKING_CHAINS 
      SET last_rownum = b2.rownum, num_snapshots = b1.num_snapshots + 1, 
        max_blocked_task_count = CASE WHEN b1.max_blocked_task_count > b2.blocked_task_count THEN b1.max_blocked_task_count ELSE b2.blocked_task_count END, 
        max_total_wait_duration_ms = CASE WHEN b1.max_total_wait_duration_ms > b2.tot_wait_duration_ms THEN b1.max_total_wait_duration_ms ELSE b2.tot_wait_duration_ms END, 
        avg_wait_duration_ms = (b1.num_snapshots-1) * b1.avg_wait_duration_ms + b2.avg_wait_duration_ms / b1.num_snapshots, 
        max_wait_duration_ms = CASE WHEN b1.max_wait_duration_ms > b2.max_wait_duration_ms THEN b1.max_wait_duration_ms ELSE b2.max_wait_duration_ms END, 
        max_blocking_chain_depth = CASE WHEN b1.max_blocking_chain_depth > b2.max_blocking_chain_depth THEN b1.max_blocking_chain_depth ELSE b2.max_blocking_chain_depth END
      FROM tbl_BLOCKING_CHAINS b1 
      INNER JOIN tbl_HEADBLOCKERSUMMARY b2 ON b1.blocking_end IS NULL -- end-of-blocking has not been detected yet
          AND b2.head_blocker_session_id = b1.head_blocker_session_id -- same head blocker
          AND b1.blocking_wait_type = b2.blocking_resource_wait_type -- same type of blocking
          AND b2.runtime = @runtime
      PRINT 'Updated ' + CONVERT (varchar, @@ROWCOUNT) + ' in-progress blocking chains...'

      -- 3) "Close out" blocking chains that were just resolved
      UPDATE tbl_BLOCKING_CHAINS 
      SET blocking_end = @runtime
      FROM tbl_BLOCKING_CHAINS b1
      WHERE blocking_end IS NULL AND NOT EXISTS (
        SELECT * FROM tbl_HEADBLOCKERSUMMARY b2 WHERE b2.runtime = @runtime 
          AND b2.head_blocker_session_id = b1.head_blocker_session_id -- same head blocker
          AND b1.blocking_wait_type = b2.blocking_resource_wait_type -- same type of blocking
      )
      PRINT + CONVERT (varchar, @@ROWCOUNT) + ' blocking chains have ended.'
    END
  END

  
  SET @rowcount = @@ROWCOUNT
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats qry4 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)

  -- Raise a diagnostic message if we use much more CPU than normal (a typical execution uses <300ms)
  DECLARE @cpu_time bigint, @elapsed_time bigint
  SELECT @cpu_time = cpu_time - @cpu_time_start, @elapsed_time = total_elapsed_time - @elapsed_time_start FROM sys.dm_exec_sessions WHERE session_id = @@SPID
  IF (@elapsed_time > 2000 OR @cpu_time > 750)
    PRINT 'DebugPrint: perfstats tot - ' + CONVERT (varchar, @elapsed_time) + 'ms elapsed, ' + CONVERT (varchar, @cpu_time) + 'ms cpu' + CHAR(13) + CHAR(10)  

  RAISERROR ('', 0, 1) WITH NOWAIT

  print '-- debug info finishing sp_perf_stats --'
  print ''


GO


IF OBJECT_ID ('sp_perf_stats_infrequent','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_infrequent
GO
CREATE PROCEDURE sp_perf_stats_infrequent @runtime datetime, @prevruntime datetime, @prevmsticks bigint, @lastmsticks bigint output, @firstrun tinyint = 0, @IsLite bit = 0
 AS 
 
  SET NOCOUNT ON
  print '-- debug info starting sp_perf_stats_infrequent --'
  print ''
  DECLARE @queryduration int
  DECLARE @querystarttime datetime
  DECLARE @qrydurationwarnthreshold int
  DECLARE @cpu_time_start bigint, @elapsed_time_start bigint
  DECLARE @servermajorversion int
  DECLARE @msg varchar(100)
  DECLARE @sql nvarchar(max)
  DECLARE @rowcount bigint
  DECLARE @msticks bigint
  DECLARE @mstickstime datetime
  DECLARE @procname varchar(50) = OBJECT_NAME(@@PROCID)

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

  SELECT /*qry1*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms, wait_type
  FROM sys.dm_os_wait_stats 
  WHERE waiting_tasks_count > 0 OR wait_time_ms > 0 OR signal_wait_time_ms > 0
  ORDER BY wait_time_ms DESC

  RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry1 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #2: Spinlock stats
  ** No DMV for this -- we will synthesize the [runtime] column during data load. */
  --PRINT ''
  --RAISERROR ('-- DBCC SQLPERF (SPINLOCKSTATS) --', 0, 1) WITH NOWAIT;
  --DBCC SQLPERF (SPINLOCKSTATS)


  /* Resultset #2a: dm_os_spinlock_stats */
  PRINT ''
  RAISERROR ('--  dm_os_spinlock_stats --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  SELECT /*qry2a*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', collisions, spins, spins_per_collision, sleep_time, backoffs, name FROM sys.dm_os_spinlock_stats

  RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry2a - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)

    
  /* Resultset #3: basic perf-related SQL perfmon counters */
  PRINT ''
  RAISERROR ('-- sysperfinfo_raw (general perf subset) --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()
 
  /* Force binary collation to speed up string comparisons (query uses 10-20ms CPU w/binary collation, 200-300ms otherwise) */
  
  SELECT /*qry3*/ 
    CONVERT (varchar(30), @runtime, 126) AS 'runtime', cntr_value,
    SUBSTRING ([object_name], CHARINDEX (':', [object_name]) + 1, 30) AS [object_name], 
    LEFT (counter_name, 40) AS 'counter_name', LEFT (instance_name, 50) AS 'instance_name'
  FROM sys.dm_os_performance_counters 
  WHERE 
       ([object_name] LIKE '%:Memory Manager%' COLLATE Latin1_General_BIN     AND counter_name COLLATE Latin1_General_BIN IN ('Connection Memory (KB)', 'Granted Workspace Memory (KB)', 'Lock Memory (KB)', 'Memory Grants Outstanding', 'Memory Grants Pending', 'Optimizer Memory (KB)', 'SQL Cache Memory (KB)'))
    OR ([object_name] LIKE '%:Buffer Manager%' COLLATE Latin1_General_BIN     AND counter_name COLLATE Latin1_General_BIN IN ('Buffer cache hit ratio', 'Buffer cache hit ratio base', 'Page lookups/sec', 'Page life expectancy', 'Lazy writes/sec', 'Page reads/sec', 'Page writes/sec', 'Checkpoint pages/sec', 'Free pages', 'Total pages', 'Target pages', 'Stolen pages'))
    OR ([object_name] LIKE '%:General Statistics%' COLLATE Latin1_General_BIN AND counter_name COLLATE Latin1_General_BIN IN ('User Connections', 'Transactions', 'Processes blocked'))
    OR ([object_name] LIKE '%:Access Methods%' COLLATE Latin1_General_BIN     AND counter_name COLLATE Latin1_General_BIN IN ('Index Searches/sec', 'Pages Allocated/sec', 'Table Lock Escalations/sec'))
    OR ([object_name] LIKE '%:SQL Statistics%' COLLATE Latin1_General_BIN     AND counter_name COLLATE Latin1_General_BIN IN ('Batch Requests/sec', 'Forced Parameterizations/sec', 'SQL Compilations/sec', 'SQL Re-Compilations/sec', 'SQL Attention rate'))
    OR ([object_name] LIKE '%:Transactions%' COLLATE Latin1_General_BIN       AND counter_name COLLATE Latin1_General_BIN IN ('Transactions', 'Snapshot Transactions', 'Longest Transaction Running Time', 'Free Space in tempdb (KB)', 'Version Generation rate (KB/s)'))
    OR ([object_name] LIKE '%:CLR%' COLLATE Latin1_General_BIN                AND counter_name COLLATE Latin1_General_BIN IN ('CLR Execution'))
    OR ([object_name] LIKE '%:Wait Statistics%' COLLATE Latin1_General_BIN    AND instance_name COLLATE Latin1_General_BIN IN ('Waits in progress', 'Average wait time (ms)'))
    OR ([object_name] LIKE '%:Exec Statistics%' COLLATE Latin1_General_BIN    AND instance_name COLLATE Latin1_General_BIN IN ('Average execution time (ms)', 'Execs in progress', 'Cumulative execution time (ms) per second'))
    OR ([object_name] LIKE '%:Plan Cache%' COLLATE Latin1_General_BIN             AND instance_name = '_Total' COLLATE Latin1_General_BIN AND counter_name COLLATE Latin1_General_BIN IN ('Cache Hit Ratio', 'Cache Hit Ratio Base', 'Cache Pages', 'Cache Object Counts'))
    OR ([object_name] LIKE '%:Locks%' COLLATE Latin1_General_BIN                  AND instance_name = '_Total' COLLATE Latin1_General_BIN AND counter_name COLLATE Latin1_General_BIN IN ('Lock Requests/sec', 'Number of Deadlocks/sec', 'Lock Timeouts (timeout > 0)/sec'))
    OR ([object_name] LIKE '%:Databases%' COLLATE Latin1_General_BIN              AND instance_name = '_Total' COLLATE Latin1_General_BIN AND counter_name COLLATE Latin1_General_BIN IN ('Data File(s) Size (KB)', 'Log File(s) Size (KB)', 'Log File(s) Used Size (KB)', 'Active Transactions', 'Transactions/sec', 'Bulk Copy Throughput/sec', 'Backup/Restore Throughput/sec', 'DBCC Logical Scan Bytes/sec', 'Log Flush Wait Time', 'Log Growths', 'Log Shrinks'))
    OR ([object_name] LIKE '%:Cursor Manager by Type%' COLLATE Latin1_General_BIN AND instance_name = '_Total' COLLATE Latin1_General_BIN AND counter_name COLLATE Latin1_General_BIN IN ('Cached Cursor Counts', 'Cursor Requests/sec', 'Cursor memory usage'))
    OR ([object_name] LIKE '%:Catalog Metadata%' COLLATE Latin1_General_BIN       AND instance_name = '_Total' COLLATE Latin1_General_BIN AND counter_name COLLATE Latin1_General_BIN IN ('Cache Hit Ratio', 'Cache Hit Ratio Base', 'Cache Entries Count'))
  
  RAISERROR (' ', 0, 1) WITH NOWAIT;

  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry3 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #4: SQL processor utilization */
  PRINT ''
  RAISERROR ('-- Recent SQL Processor Utilization (Health Records) --', 0, 1) WITH NOWAIT;
  SELECT @querystarttime = GETDATE(), @msticks = ms_ticks from sys.dm_os_sys_info
  SET @mstickstime = @querystarttime
  
  SELECT  /*qry4*/
      CONVERT (varchar(30), @runtime, 126) AS 'runtime', 
      record.value('(Record/@id)[1]', 'int') AS 'record_id',
      CONVERT (varchar, DATEADD (ms, -1 * (@msticks - [timestamp]),@mstickstime), 126) AS 'EventTime', [timestamp], 
      record.value('(Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS 'system_idle_cpu',
      record.value('(Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS 'sql_cpu_utilization' 
    FROM (
      SELECT timestamp, CONVERT (xml, record) AS 'record' 
      FROM sys.dm_os_ring_buffers 
      WHERE [timestamp] > @prevmsticks
        AND ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
		and record LIKE '%<SystemHealth>%') AS t
    ORDER BY record.value('(Record/@id)[1]', 'int') 
   
   RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry4 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #5: sys.dm_os_sys_info 
  ** used to determine the # of CPUs SQL is able to use at the moment */
  PRINT ''
  RAISERROR ('-- sys.dm_os_sys_info --', 0, 1) WITH NOWAIT;
  SELECT /*qry5*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', * FROM sys.dm_os_sys_info


  /* Resultset #6: sys.dm_os_latch_stats */
  PRINT ''
  RAISERROR ('-- sys.dm_os_latch_stats --', 0, 1) WITH NOWAIT;
  SELECT /*qry6*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', waiting_requests_count, wait_time_ms, max_wait_time_ms, latch_class
    FROM sys.dm_os_latch_stats 
	WHERE waiting_requests_count > 0 OR wait_time_ms > 0 OR max_wait_time_ms > 0
    ORDER BY wait_time_ms DESC


  /* Resultset #7: File Stats Full
  ** To conserve space, output full dbname and filenames on 1st execution only. */
  PRINT ''
  RAISERROR ('-- File Stats (full) --', 0, 1) WITH NOWAIT;
  SET @sql = 'SELECT /*' + @procname + ':7 */ CONVERT (varchar(30), @runtime, 126) AS runtime, 
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

  RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry7 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)

 
  /* Resultset #8: dm_exec_query_resource_semaphores 
  ** no reason to list columns since no long character columns */
  PRINT ''
  RAISERROR ('-- dm_exec_query_resource_semaphores --', 0, 1) WITH NOWAIT;
  SELECT /*qry8*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_exec_query_resource_semaphores


  /* Resultset #9: dm_exec_query_memory_grants 
  ** Query sometimes causes follow message:
  ** Warning: The join order has been enforced because a local join hint is used.*/
  PRINT ''
  RAISERROR ('-- dm_exec_query_memory_grants --', 0, 1) WITH NOWAIT;
  SELECT /*qry9*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', session_id, request_id, scheduler_id, dop, request_time, grant_time, requested_memory_kb, 
		granted_memory_kb, required_memory_kb, used_memory_kb, max_used_memory_kb, query_cost, timeout_sec, resource_semaphore_id, queue_id, wait_order, is_next_candidate, 
		wait_time_ms, group_id, pool_id, is_small ideal_memory_kb, plan_handle, [sql_handle],
		convert(smallint, substring(plan_handle,4,1) + substring(plan_handle,3,1)) as [database_id],
		case when substring(plan_handle,1,1) = 0x05 then convert(int, substring(plan_handle,8,1) + substring(plan_handle,7,1) + substring(plan_handle,6,1) + substring(plan_handle,5,1))
			else NULL end as [object_id],
		case when substring(plan_handle,1,1) = 0x05 then 
			'[' + DB_NAME(convert(smallint, substring(plan_handle,4,1) + substring(plan_handle,3,1)))
			+ '].[' + object_schema_name(convert(int, substring(plan_handle,8,1) + substring(plan_handle,7,1) + substring(plan_handle,6,1) + substring(plan_handle,5,1)),convert(smallint, substring(plan_handle,4,1) + substring(plan_handle,3,1)))
			+ '].['+ object_name(convert(int, substring(plan_handle,8,1) + substring(plan_handle,7,1) + substring(plan_handle,6,1) + substring(plan_handle,5,1)),convert(smallint, substring(plan_handle,4,1) + substring(plan_handle,3,1))) + ']' 
			else 'ad-hoc query, see notableactivequeries for text' end as 'full_object_name'
	from sys.dm_exec_query_memory_grants

  /* Resultset #10: dm_os_memory_brokers */
  PRINT ''
  RAISERROR ('-- dm_os_memory_brokers --', 0, 1) WITH NOWAIT;
  SELECT /*qry10*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', pool_id, allocations_kb, allocations_kb_per_sec, predicted_allocations_kb, target_allocations_kb, future_allocations_kb, overall_limit_kb, last_notification, memory_broker_type from sys.dm_os_memory_brokers

  /* Resultset #11: dm_os_schedulers 
  ** no reason to list columns since no long character columns */
  PRINT ''
  RAISERROR ('-- dm_os_schedulers --', 0, 1) WITH NOWAIT;
  select /*qry11*/ CONVERT (varchar(30), @runtime, 126) as 'runtime', * from sys.dm_os_schedulers


  /* Resultset #12: dm_os_nodes */
  PRINT ''
  RAISERROR ('-- sys.dm_os_nodes --', 0, 1) WITH NOWAIT;
  SELECT /*qry12*/ CONVERT (varchar(30), @runtime, 126) as 'runtime', node_id, memory_object_address, memory_clerk_address, io_completion_worker_address, memory_node_id, cpu_affinity_mask, online_scheduler_count, idle_scheduler_count, active_worker_count, avg_load_balance, timer_task_affinity_mask, permanent_task_affinity_mask, resource_monitor_state,/* online_scheduler_mask,*/ /*processor_group,*/ node_state_desc FROM sys.dm_os_nodes


  /* Resultset #13: dm_os_memory_nodes 
  ** no reason to list columns since no long character columns */
  PRINT ''
  RAISERROR ('-- sys.dm_os_memory_nodes --', 0, 1) WITH NOWAIT;
  SELECT /*qry13*/ CONVERT (varchar(30), @runtime, 126) as 'runtime',* FROM sys.dm_os_memory_nodes


  /* Resultset #14: Lock summary */
  PRINT ''
  RAISERROR ('-- Lock summary --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  select /*qry14*/ CONVERT (varchar(30), @runtime, 126) as 'runtime', * from 
    (select  count (*) as 'LockCount', Resource_database_id, LEFT(resource_type,15) as 'resource_type', LEFT(request_mode,20) as 'request_mode', request_status from sys.dm_tran_locks 
      group by  Resource_database_id, resource_type, request_mode, request_status ) t

   RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry14 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #15: Thread Statistics */
  PRINT ''
  RAISERROR ('-- Thread Statistics --', 0, 1) WITH NOWAIT
  SET @querystarttime = GETDATE()

  select /*qry15*/ CONVERT (varchar(30), @runtime, 126) as 'runtime', th.os_thread_id, ta.scheduler_id, ta.session_id, ta.request_id, req.command, usermode_time, kernel_time, req.cpu_time as 'req_cpu_time',  req.logical_reads,req.total_elapsed_time,
      REPLACE (REPLACE (SUBSTRING (sql.[text], CHARINDEX ('CREATE ', CONVERT (nvarchar(512), SUBSTRING (sql.[text], 1, 1000)) COLLATE Latin1_General_BIN), 50) COLLATE Latin1_General_BIN, CHAR(10), ' '), CHAR(13), ' ') as 'QueryText'
    from sys.dm_os_threads th join sys.dm_os_tasks ta on th.worker_address = ta.worker_address
      left outer join sys.dm_exec_requests req on ta.session_id = req.session_id and ta.request_id = req.request_id
      outer apply sys.dm_exec_sql_text (req.sql_handle) sql

	  RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry15 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #16: dm_db_file_space_usage 
  ** must be run from tempdb */
  PRINT ''
  RAISERROR ('-- dm_db_file_space_usage --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  SELECT /*qry16*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', * FROM sys.dm_db_file_space_usage

  RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry16 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #17: dm_exec_cursors(0) */
  PRINT ''
  RAISERROR ('-- dm_exec_cursors(0) --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  SELECT /*qry17*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', COUNT(*) AS 'count', SUM(CONVERT(INT,is_open)) AS 'open count', MIN(creation_time) AS 'oldest create',[properties]
    FROM sys.dm_exec_cursors(0)
    GROUP BY [properties]

	RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry17 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #18:  dm_os_ring_buffers for connectivity
  ** return all rows on first run and then after only new rows in later runs */
  PRINT ''
  RAISERROR ('-- dm_os_ring_buffers --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  SET @sql = '
    SELECT /*' + @procname + ':18*/  
        CONVERT (varchar(30), @runtime, 126) AS runtime, 
		CONVERT (varchar(23), DATEADD (ms, -1 * (@msticks - [timestamp]), @mstickstime), 126) AS EventTime, 
		[record] 
      FROM sys.dm_os_ring_buffers 
      WHERE [timestamp] > @prevmsticks 
        AND ring_buffer_type in (''RING_BUFFER_CONNECTIVITY'',''RING_BUFFER_SECURITY_ERROR'')
      ORDER BY [timestamp]'

  EXEC sp_executesql @sql, N'@runtime datetime, @prevmsticks bigint, @msticks bigint, @mstickstime datetime', @runtime = @runtime, @prevmsticks = @prevmsticks, @msticks = @msticks, @mstickstime = @mstickstime


  RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  --SET @lastmsticks = @msticks		
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry18 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #19: Plan Cache Stats */
  PRINT ''
  RAISERROR ('-- Plan Cache Stats --', 0, 1) WITH NOWAIT;
  SET @querystarttime = GETDATE()

  SELECT /*qry19*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime',*  from 
    (select  objtype, sum(cast(size_in_bytes as bigint) /cast(1024.00 as decimal(38,2)) /1024.00) 'Cache_Size_MB' , count_big (*) 'Entry_Count', isnull(db_name(cast (value as int)),'mssqlsystemresource') 'db name'
	  from  sys.dm_exec_cached_plans AS p CROSS APPLY sys.dm_exec_plan_attributes ( plan_handle ) as t 
      where attribute='dbid'
      group by  isnull(db_name(cast (value as int)),'mssqlsystemresource'), objtype )  t
    order by Entry_Count desc


	RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry19 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)


  /* Resultset #20: System Requests */
  PRINT ''
  RAISERROR ('-- System Requests --', 0, 1) WITH NOWAIT
  SET @querystarttime = GETDATE()
  
  select /*qry20*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime', tr.os_thread_id, req.* 
    from sys.dm_exec_requests req 
	  join sys.dm_os_workers wrk  on req.task_address = wrk.task_address and req.connection_id is null
      join sys.dm_os_threads tr on tr.worker_address=wrk.worker_address


	  RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @rowcount = @@ROWCOUNT
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry20 - ' + CONVERT (varchar, @queryduration) + 'ms, rowcount=' + CONVERT(varchar, @rowcount) + CHAR(13) + CHAR(10)


  /* Resultset #21: sys.dm_os_process_memory */
  print ''
  RAISERROR ('-- sys.dm_os_process_memory --', 0, 1) WITH NOWAIT
  SET @querystarttime = GETDATE()

  select /*qry21*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime',* from sys.dm_os_process_memory

  RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry21 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)

  /* Resultset #22: sys.dm_os_sys_memory */
  print ''
  RAISERROR ('-- sys.dm_os_sys_memory --', 0, 1) WITH NOWAIT
  SET @querystarttime = GETDATE()

  select /*qry22*/ CONVERT (varchar(30), @runtime, 126) AS 'runtime',* from sys.dm_os_sys_memory

  RAISERROR (' ', 0, 1) WITH NOWAIT;
  SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
  IF @queryduration > @qrydurationwarnthreshold
    PRINT 'DebugPrint: perfstats2 qry22 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)

  /* Resultset #23:  dm_os_ring_buffers for security cache
  ** return all rows on first run and then after only new rows in later runs */
	IF (CONVERT(smallint,SERVERPROPERTY ('ProductMajorVersion')) < 15)
		PRINT '' -- we do not capture this information for versions lower than SQL 2019
	ELSE
		BEGIN
			PRINT ''
			RAISERROR ('-- dm_os_ring_buffers_sec_cache --', 0, 1) WITH NOWAIT;
			SET @querystarttime = GETDATE()

			SET @sql = '
				SELECT /*' + @procname + ':23*/  
					CONVERT (varchar(30), @runtime, 126) AS runtime, 
					CONVERT (varchar(23), DATEADD (ms, -1 * (@msticks - [timestamp]), @mstickstime), 126) AS EventTime, 
					[record] 
				  FROM sys.dm_os_ring_buffers 
				  WHERE [timestamp] > @prevmsticks 
					AND ring_buffer_type in (''RING_BUFFER_SECURITY_CACHE'')
				  ORDER BY [timestamp]'

			EXEC sp_executesql @sql, N'@runtime datetime, @prevmsticks bigint, @msticks bigint, @mstickstime datetime', @runtime = @runtime, @prevmsticks = @prevmsticks, @msticks = @msticks, @mstickstime = @mstickstime


			RAISERROR (' ', 0, 1) WITH NOWAIT;
			SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
			IF @queryduration > @qrydurationwarnthreshold
				PRINT 'DebugPrint: perfstats2 qry23 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)
		END
	SET @lastmsticks = @msticks	-- Note that this is used by multiple ring buffer queries in this proc so be careful where you position this

  /* Raise a diagnostic message if we use more CPU than normal (a typical execution uses <200ms) */
  DECLARE @cpu_time bigint, @elapsed_time bigint
  SELECT @cpu_time = cpu_time - @cpu_time_start, @elapsed_time = total_elapsed_time - @elapsed_time_start FROM sys.dm_exec_sessions WHERE session_id = @@SPID
  IF (@elapsed_time > 3000 OR @cpu_time > 1000) BEGIN
    PRINT ''
    PRINT 'DebugPrint: perfstats2 tot - ' + CONVERT (varchar, @elapsed_time) + 'ms elapsed, ' + CONVERT (varchar, @cpu_time) + 'ms cpu' + CHAR(13) + CHAR(10)  
  END

  RAISERROR ('', 0, 1) WITH NOWAIT;
  print '-- debug info finishing sp_perf_stats_infrequent --'
  print ''

GO
IF OBJECT_ID ('sp_mem_stats_grants','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats_grants
GO

CREATE PROCEDURE sp_mem_stats_grants @runtime datetime , @lastruntime datetime =null
as
print '-- query execution memory --'
SELECT    CONVERT (varchar(30), @runtime, 121) as runtime, 
		r.session_id
         , r.blocking_session_id
         , r.cpu_time
         , r.total_elapsed_time
         , r.reads
         , r.writes
         , r.logical_reads
         , r.row_count
         , wait_time
         , wait_type
         , r.command
         , ltrim(rtrim(replace(replace (substring (q.text, 1, 1000), char(10), ' '), char(13), ' '))) [text]
         --, REPLACE (REPLACE (SUBSTRING (q.[text] COLLATE Latin1_General_BIN, CHARINDEX (''CREATE '', SUBSTRING (q.[text] COLLATE Latin1_General_BIN, 1, 1000)), 50), CHAR(10), '' ''), CHAR(13), '' '')
         --, q.TEXT  --Full SQL Text
         , s.login_time
         , d.name
         , s.login_name
         , s.host_name
         , s.nt_domain
         , s.nt_user_name
         , s.status
         , c.client_net_address
         , s.program_name
         , s.client_interface_name
--         , s.total_elapsed_time
         , s.last_request_start_time
         , s.last_request_end_time
         , c.connect_time
         , c.last_read
         , c.last_write
         , mg.dop --Degree of parallelism 
         , mg.request_time  --Date and time when this query requested the memory grant.
         , mg.grant_time --NULL means memory has not been granted
         , mg.requested_memory_kb
          / 1024 requested_memory_mb --Total requested amount of memory in megabytes
         , mg.granted_memory_kb
          / 1024 AS granted_memory_mb --Total amount of memory actually granted in megabytes. NULL if not granted
         , mg.required_memory_kb
          / 1024 AS required_memory_mb--Minimum memory required to run this query in megabytes. 
         , max_used_memory_kb
          / 1024 AS max_used_memory_mb
         , mg.query_cost --Estimated query cost.
         , mg.timeout_sec --Time-out in seconds before this query gives up the memory grant request.
         , mg.resource_semaphore_id --Nonunique ID of the resource semaphore on which this query is waiting.
         , mg.wait_time_ms --Wait time in milliseconds. NULL if the memory is already granted.
         , CASE mg.is_next_candidate --Is this process the next candidate for a memory grant
           WHEN 1 THEN 'Yes'
           WHEN 0 THEN 'No'
           ELSE 'Memory has been granted'
         END AS 'Next Candidate for Memory Grant'
         , rs.target_memory_kb
          / 1024 AS server_target_memory_mb --Grant usage target in megabytes.
         , rs.max_target_memory_kb
          / 1024 AS server_max_target_memory_mb --Maximum potential target in megabytes. NULL for the small-query resource semaphore.
         , rs.total_memory_kb
          / 1024 AS server_total_memory_mb --Memory held by the resource semaphore in megabytes. 
         , rs.available_memory_kb
          / 1024 AS server_available_memory_mb --Memory available for a new grant in megabytes.
         , rs.granted_memory_kb
          / 1024 AS server_granted_memory_mb  --Total granted memory in megabytes.
         , rs.used_memory_kb
          / 1024 AS server_used_memory_mb --Physically used part of granted memory in megabytes.
         , rs.grantee_count --Number of active queries that have their grants satisfied.
         , rs.waiter_count --Number of queries waiting for grants to be satisfied.
         , rs.timeout_error_count --Total number of time-out errors since server startup. NULL for the small-query resource semaphore.
         , rs.forced_grant_count --Total number of forced minimum-memory grants since server startup. NULL for the small-query resource semaphore.
FROM     sys.dm_exec_requests r
         JOIN sys.dm_exec_connections c
           ON r.connection_id = c.connection_id
         JOIN sys.dm_exec_sessions s
           ON c.session_id = s.session_id
         JOIN sys.databases d
           ON r.database_id = d.database_id
         JOIN sys.dm_exec_query_memory_grants mg
           ON s.session_id = mg.session_id
         INNER JOIN sys.dm_exec_query_resource_semaphores rs
           ON mg.resource_semaphore_id = rs.resource_semaphore_id
         CROSS APPLY sys.dm_exec_sql_text (r.sql_handle ) AS q
ORDER BY wait_time DESC
RAISERROR ('', 0, 1) WITH NOWAIT


go

go

IF OBJECT_ID ('sp_perf_stats_reallyinfrequent','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_reallyinfrequent
GO
CREATE PROCEDURE sp_perf_stats_reallyinfrequent @runtime datetime, @firstrun int = 0, @IsLite bit=0
 AS 
 set quoted_identifier on
  print '-- debug info starting sp_perf_stats_reallyinfrequent  --'
  print ''

DECLARE @qrydurationwarnthreshold int = 750
DECLARE @queryduration int
DECLARE @querystarttime datetime


exec sp_mem_stats_grants @runtime

RAISERROR (' ', 0, 1) WITH NOWAIT;
SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
IF @queryduration > @qrydurationwarnthreshold
  PRINT 'DebugPrint: perfstats3 qry1 - ' + CONVERT (varchar, @queryduration) + 'ms' + CHAR(13) + CHAR(10)

RAISERROR ('', 0, 1) WITH NOWAIT

  print '-- debug info finishing sp_perf_stats_reallyinfrequent  --'
  print ''

go
IF OBJECT_ID ('sp_perf_stats10','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats10
GO
go
CREATE PROCEDURE sp_perf_stats10 @appname sysname='PSSDIAG', @runtime datetime, @prevruntime datetime, @IsLite bit =0 
AS 
begin
	exec sp_perf_stats @appname, @runtime, @prevruntime, @IsLite
end

go
IF OBJECT_ID ('sp_perf_stats11','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats11
GO
go
CREATE PROCEDURE sp_perf_stats11 @appname sysname='PSSDIAG', @runtime datetime, @prevruntime datetime , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats10 @appname, @runtime, @prevruntime, @IsLite
end

go

IF OBJECT_ID ('sp_perf_stats12','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats12
GO
go
CREATE PROCEDURE sp_perf_stats12 @appname sysname='PSSDIAG', @runtime datetime, @prevruntime datetime , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats11 @appname, @runtime, @prevruntime, @IsLite
end

go

IF OBJECT_ID ('sp_perf_stats13','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats13
GO
go
CREATE PROCEDURE sp_perf_stats13 @appname sysname='PSSDIAG', @runtime datetime, @prevruntime datetime , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats12 @appname, @runtime, @prevruntime, @IsLite
end
go
IF OBJECT_ID ('sp_perf_stats14','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats14
GO
go
CREATE PROCEDURE sp_perf_stats14 @appname sysname='PSSDIAG', @runtime datetime, @prevruntime datetime , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats13 @appname, @runtime, @prevruntime, @IsLite
end
go
IF OBJECT_ID ('sp_perf_stats15','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats15
GO
go
CREATE PROCEDURE sp_perf_stats15 @appname sysname='PSSDIAG', @runtime datetime, @prevruntime datetime , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats14 @appname, @runtime, @prevruntime, @IsLite
end
go

IF OBJECT_ID ('sp_perf_stats_infrequent10','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_infrequent10
GO
CREATE PROCEDURE sp_perf_stats_infrequent10 @runtime datetime, @prevruntime datetime, @prevmsticks bigint, @lastmsticks bigint output, @firstrun tinyint = 0, @IsLite bit =0 
 AS 
begin
	exec sp_perf_stats_infrequent @runtime, @prevruntime, @prevmsticks, @lastmsticks output, @firstrun, @IsLite
end
go

IF OBJECT_ID ('sp_perf_stats_infrequent11','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_infrequent11
GO
CREATE PROCEDURE sp_perf_stats_infrequent11 @runtime datetime, @prevruntime datetime, @prevmsticks bigint, @lastmsticks bigint output, @firstrun tinyint = 0, @IsLite bit =0 
 AS 
begin
	exec sp_perf_stats_infrequent10 @runtime, @prevruntime, @prevmsticks, @lastmsticks output, @firstrun, @IsLite
end

go

IF OBJECT_ID ('sp_perf_stats_infrequent12','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_infrequent12
GO
CREATE PROCEDURE sp_perf_stats_infrequent12 @runtime datetime, @prevruntime datetime, @prevmsticks bigint, @lastmsticks bigint output, @firstrun tinyint = 0, @IsLite bit =0 
 AS 
begin
	exec sp_perf_stats_infrequent11 @runtime, @prevruntime, @prevmsticks, @lastmsticks output, @firstrun, @IsLite
end
go

IF OBJECT_ID ('sp_perf_stats_infrequent13','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_infrequent13
GO
CREATE PROCEDURE sp_perf_stats_infrequent13 @runtime datetime, @prevruntime datetime, @prevmsticks bigint, @lastmsticks bigint output, @firstrun tinyint = 0, @IsLite bit =0 
 AS 
begin
	exec sp_perf_stats_infrequent12 @runtime, @prevruntime, @prevmsticks, @lastmsticks output, @firstrun, @IsLite
end

go
IF OBJECT_ID ('sp_perf_stats_infrequent14','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_infrequent14
GO
CREATE PROCEDURE sp_perf_stats_infrequent14 @runtime datetime, @prevruntime datetime, @prevmsticks bigint, @lastmsticks bigint output, @firstrun tinyint = 0, @IsLite bit =0 
 AS 
begin
	exec sp_perf_stats_infrequent13 @runtime, @prevruntime, @prevmsticks, @lastmsticks output, @firstrun, @IsLite
end

go
IF OBJECT_ID ('sp_perf_stats_infrequent15','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_infrequent15
GO
CREATE PROCEDURE sp_perf_stats_infrequent15 @runtime datetime, @prevruntime datetime, @prevmsticks bigint, @lastmsticks bigint output, @firstrun tinyint = 0, @IsLite bit =0 
 AS 
begin
	exec sp_perf_stats_infrequent14 @runtime, @prevruntime, @prevmsticks, @lastmsticks output, @firstrun, @IsLite
end

go



IF OBJECT_ID ('sp_perf_stats_reallyinfrequent10','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_reallyinfrequent10
GO
CREATE PROCEDURE sp_perf_stats_reallyinfrequent10 @runtime datetime, @firstrun int = 0 , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats_reallyinfrequent @runtime, @firstrun , @IsLite
end

go


IF OBJECT_ID ('sp_perf_stats_reallyinfrequent11','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_reallyinfrequent11
GO
CREATE PROCEDURE sp_perf_stats_reallyinfrequent11 @runtime datetime, @firstrun int = 0 , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats_reallyinfrequent10 @runtime, @firstrun , @IsLite
end

go


IF OBJECT_ID ('sp_perf_stats_reallyinfrequent12','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_reallyinfrequent12
GO
CREATE PROCEDURE sp_perf_stats_reallyinfrequent12 @runtime datetime, @firstrun int = 0 , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats_reallyinfrequent11 @runtime, @firstrun , @IsLite
end

go

IF OBJECT_ID ('sp_perf_stats_reallyinfrequent13','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_reallyinfrequent13
GO
CREATE PROCEDURE sp_perf_stats_reallyinfrequent13 @runtime datetime, @firstrun int = 0 , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats_reallyinfrequent12 @runtime, @firstrun , @IsLite
end


go

IF OBJECT_ID ('sp_perf_stats_reallyinfrequent14','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_reallyinfrequent14
GO
CREATE PROCEDURE sp_perf_stats_reallyinfrequent14 @runtime datetime, @firstrun int = 0 , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats_reallyinfrequent13 @runtime, @firstrun , @IsLite
end


go

IF OBJECT_ID ('sp_perf_stats_reallyinfrequent15','P') IS NOT NULL
   DROP PROCEDURE sp_perf_stats_reallyinfrequent15
GO
CREATE PROCEDURE sp_perf_stats_reallyinfrequent15 @runtime datetime, @firstrun int = 0 , @IsLite bit =0 
AS 
begin
	exec sp_perf_stats_reallyinfrequent14 @runtime, @firstrun , @IsLite
end


go



IF OBJECT_ID ('sp_Run_PerfStats','P') IS NOT NULL
   DROP PROCEDURE sp_Run_PerfStats
GO
create procedure sp_Run_PerfStats @IsLite bit = 0
as
  -- Main loop
  
PRINT 'Starting SQL Server Perf Stats Script...'
SET LANGUAGE us_english
PRINT '-- Script Source --'
SELECT 'SQL Server Perf Stats Script' AS script_name, '$Revision: 16 $ ($Change: ? $)' AS revision
PRINT ''
PRINT '-- Script and Environment Details --'
PRINT 'Name                     Value'
PRINT '------------------------ ---------------------------------------------------'
PRINT 'SQL Server Name          ' + @@SERVERNAME
PRINT 'Machine Name             ' + CONVERT (varchar, SERVERPROPERTY ('MachineName'))
PRINT 'SQL Version (SP)         ' + CONVERT (varchar, SERVERPROPERTY ('ProductVersion')) + ' (' + CONVERT (varchar, SERVERPROPERTY ('ProductLevel')) + ')'
PRINT 'Edition                  ' + CONVERT (varchar, SERVERPROPERTY ('Edition'))
PRINT 'Script Name              SQL Server Perf Stats Script'
PRINT 'Script File Name         $File: SQL_Server_Perf_Stats.sql $'
PRINT 'Revision                 $Revision: 16 $ ($Change: ? $)'
PRINT 'Last Modified            $Date: 2015/10/15  $'
PRINT 'Script Begin Time        ' + CONVERT (varchar(30), GETDATE(), 126) 
PRINT 'Current Database         ' + DB_NAME()
PRINT '@@SPID                   ' + LTRIM(STR(@@SPID))
PRINT ''

DECLARE @firstrun tinyint = 1
DECLARE @msg varchar(100)
DECLARE @runtime datetime
DECLARE @prevruntime datetime
DECLARE @previnfreqruntime datetime
DECLARE @prevreallyinfreqruntime datetime
DECLARE @lastmsticks bigint = 0
DECLARE @prevmsticks bigint = 0

SELECT @prevruntime = sqlserver_start_time from sys.dm_os_sys_info
print 'Start SQLServer time: ' + convert(varchar(23), @prevruntime, 126)
sET @prevruntime = DATEADD(SECOND, -300, @prevruntime)
SET @previnfreqruntime = @prevruntime
SET @prevreallyinfreqruntime = @prevruntime

DECLARE @servermajorversion nvarchar(2)
SET @servermajorversion = REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')
declare @sp_perf_stats_ver sysname, @sp_perf_stats_reallyinfrequent_ver sysname, @sp_perf_stats_infrequent_ver sysname
set @sp_perf_stats_ver = 'sp_perf_stats' + @servermajorversion
set @sp_perf_stats_infrequent_ver = 'sp_perf_stats_infrequent' -- + @servermajorversion
set @sp_perf_stats_reallyinfrequent_ver = 'sp_perf_stats_reallyinfrequent' + @servermajorversion


  WHILE (1=1)
  BEGIN
    SET @runtime = GETDATE()
    SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)

    PRINT ''
    RAISERROR (@msg, 0, 1) WITH NOWAIT
  
    -- Collect sp_perf_stats every 10 seconds
    --EXEC dbo.sp_perf_stats @appname = 'pssdiag', @runtime = @runtime, @prevruntime = @prevruntime
	exec @sp_perf_stats_ver 'pssdiag', @runtime = @runtime, @prevruntime = @prevruntime, @IsLite=@IsLite

		
    -- Collect sp_perf_stats_infrequent approximately every minute
    if DATEDIFF(SECOND, @previnfreqruntime,GETDATE()) > 59
    BEGIN
      EXEC @sp_perf_stats_infrequent_ver  @runtime = @runtime, @prevruntime = @previnfreqruntime, @prevmsticks = @prevmsticks, @lastmsticks = @lastmsticks output, @firstrun = @firstrun,  @IsLite=@IsLite
	  SET @prevmsticks = @lastmsticks
	  SET @previnfreqruntime = @runtime
    END

    -- Collect sp_perf_stats_reallyinfrequent approximately every 5 minutes		
    if DATEDIFF(SECOND, @prevreallyinfreqruntime,GETDATE()) > 299
    BEGIN
      EXEC @sp_perf_stats_reallyinfrequent_ver  @runtime = @runtime, @firstrun = @firstrun,  @IsLite=@IsLite
      SET @firstrun = 0
      SET @prevreallyinfreqruntime = @runtime
    END
	  
    SET @prevruntime = @runtime
    WAITFOR DELAY '0:0:10'
  END

GO


exec sp_Run_PerfStats