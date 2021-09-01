
IF OBJECT_ID ('sp_perf_never_ending_query_snapshots','P') IS NOT NULL
   DROP PROCEDURE sp_perf_never_ending_query_snapshots
GO

CREATE PROCEDURE sp_perf_never_ending_query_snapshots @appname sysname='PSSDIAG', @runtime datetime, @runtime_utc datetime
as

set nocount on 
BEGIN
 DECLARE @msg varchar(100)

 IF NOT EXISTS (SELECT * FROM sys.dm_exec_requests req left outer join sys.dm_exec_sessions sess
				on req.session_id = sess.session_id
				WHERE req.session_id <> @@SPID AND ISNULL (sess.host_name, '') != @appname and is_user_process = 1) 
  BEGIN
    PRINT 'No active queries'
  END
 ELSE 
  BEGIN

--  select '' 

    IF @runtime IS NULL or @runtime_utc IS NULL
      BEGIN 
        SET @runtime = GETDATE()
		SET @runtime_utc = GETUTCDATE()
        --SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
        RAISERROR (@msg, 0, 1) WITH NOWAIT
      END


	
	print ''
	RAISERROR ('--  neverending_query --', 0, 1) WITH NOWAIT

           --query the DMV in a loop to compare the 
        SELECT CONVERT (varchar(30), @runtime, 126) as runtime,
            CONVERT (varchar(30), @runtime_utc, 126) as runtime_utc,
            qp.session_id,
            text,
            qp.physical_operator_name,
            qp.node_id,
            qp.row_count,
            qp.rewind_count,
            qp.rebind_count, end_of_scan_count,
            qp.estimate_row_count,
            er.cpu_time,
            er.total_elapsed_time
        FROM sys.dm_exec_query_profiles qp 
		LEFT OUTER JOIN sys.dm_exec_requests er
			ON qp.session_id = er.session_id
		CROSS APPLY sys.dm_exec_sql_text(qp.sql_handle) st
		WHERE qp.session_id != @@SPID  
			AND er.cpu_time > 60000
        ORDER BY qp.node_id
		--this is to prevent massive grants
		OPTION (max_grant_percent = 3, MAXDOP 1)
    
	--flush results to client
	RAISERROR (' ', 0, 1) WITH NOWAIT
  END
END
GO



IF OBJECT_ID ('sp_Run_NeverEndingQuery_Stats','P') IS NOT NULL
   DROP PROCEDURE sp_Run_NeverEndingQuery_Stats
GO

create procedure sp_Run_NeverEndingQuery_Stats
as


--handle SQL Server 2008 code line, thus need to parse ProductVersion
DECLARE @servermajorversion int
SET @servermajorversion = CONVERT (INT, (REPLACE (LEFT (CONVERT (nvarchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')))

if (@servermajorversion < 12)
begin
    RAISERROR ('SQL Server version is less than 2014. No additional data can be collected', 0, 1) WITH NOWAIT
    return
end

declare @serverbuild int
SET @serverbuild = CONVERT (int, SERVERPROPERTY ('ProductBuild'))




--minimum build 12.0.5000.0 , see https://docs.microsoft.com/en-us/sql/relational-databases/performance/query-profiling-infrastructure?view=sql-server-ver15
if (@servermajorversion <= 12 and @serverbuild < 5000)
begin
    RAISERROR ('Your SQL Sever version does not support collecting real-time perf stats on long-running query', 0, 1) WITH NOWAIT
end
--13.0.4001.0 (SP1)
else if ((@servermajorversion = '13' and @serverbuild <4001) or (@servermajorversion = 12 and @serverbuild >= 5000))
begin
    RAISERROR ('Version SQL 2016 RTM (less than SP1) or SQL 2014 SP2+. Using Lightweight Profiling Ver1', 0, 1) WITH NOWAIT
    --create the event 

    CREATE EVENT SESSION [pssdiag_query_thread_profile] ON SERVER
    ADD EVENT sqlserver.query_thread_profile(
    ACTION(sqlos.scheduler_id,sqlserver.server_instance_name,sqlserver.session_id))
    ADD TARGET package0.ring_buffer(SET max_memory=(25600))
    WITH (MAX_MEMORY=4096 KB,
    EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY=30 SECONDS,
    MAX_EVENT_SIZE=0 KB,
    MEMORY_PARTITION_MODE=NONE,
    TRACK_CAUSALITY=OFF,
    STARTUP_STATE=OFF);

    ALTER EVENT SESSION [pssdiag_query_thread_profile] 
    ON SERVER
    STATE = START

	--TODO:
	-- TURN OFF THE XEVENT WHEN DONE - how do we hide checkbox in the GUI
	-- ALSO RUN BATCH SCRIPT TO GET PLANS 

    WHILE (1=1)
	BEGIN
        --query the DMV in a loop to compare the 
		EXEC sp_perf_never_ending_query_snapshots @appname = 'PSSDIAG'
        WAITFOR DELAY '00:00:10'
    END

end
else if ((@servermajorversion = '13' and @serverbuild >=4001) or @servermajorversion = '14')
begin
    RAISERROR ('Version SQL 2016 SP1+ or 2017. Using Lightweight Profiling Ver2', 0, 1) WITH NOWAIT
    --dbcc traceoff (7412, -1)

    WHILE (1=1)
	BEGIN
        --query the DMV in a loop to compare the 
		EXEC sp_perf_never_ending_query_snapshots @appname = 'PSSDIAG'
        WAITFOR DELAY '00:00:10'
    END

end
else if (@servermajorversion >= '15')
begin
    RAISERROR ('Version SQL 2019. Using Lightweight Profiling Ver3 (enabled by default)', 0, 1) WITH NOWAIT

	WHILE (1=1)
	BEGIN
        --query the DMV in a loop to compare the 
		EXEC sp_perf_never_ending_query_snapshots @appname = 'PSSDIAG'
        WAITFOR DELAY '00:00:10'
    END
end

go
exec sp_Run_NeverEndingQuery_Stats
