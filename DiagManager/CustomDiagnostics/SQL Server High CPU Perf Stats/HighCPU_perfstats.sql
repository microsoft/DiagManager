use tempdb
go
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



IF OBJECT_ID ('sp_perf_high_cpu_snapshots','P') IS NOT NULL
   DROP PROCEDURE sp_perf_high_cpu_snapshots
GO

CREATE PROCEDURE sp_perf_high_cpu_snapshots @appname sysname='PSSDIAG', @runtime datetime, @runtime_utc datetime
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
        SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
        RAISERROR (@msg, 0, 1) WITH NOWAIT
      END


	
	print ''
	RAISERROR ('--  high_cpu_queries --', 0, 1) WITH NOWAIT

    select	CONVERT (varchar(30), @runtime, 126) as runtime, CONVERT (varchar(30), @runtime_utc, 126) as runtime_utc, req.session_id, req.start_time as request_start_time, req.cpu_time, req.total_elapsed_time, req.logical_reads,
    		req.status, req.command, req.wait_type, req.wait_time, req.scheduler_id, req.granted_query_memory, tsk.task_state, tsk.context_switches_count,
    		replace(replace(substring(ISNULL(SQLText.text, ''),1,1000),CHAR(10), ' '),CHAR(13), ' ')  as batch_text, 
			ISNULL(sess.program_name, '') as program_name, ISNULL (sess.host_name, '') as Host_name, ISNULL(sess.host_process_id,0) as session_process_id, 
    		ISNULL (conn.net_packet_size, 0) AS 'net_packet_size', LEFT (ISNULL (conn.client_net_address, ''), 20) AS 'client_net_address',
			substring
    		(REPLACE
    		(REPLACE
    			(SUBSTRING
    			(SQLText.text
    			, (req.statement_start_offset/2) + 1
    			, (
    				(CASE statement_END_offset
    					WHEN -1
    					THEN DATALENGTH(SQLText.text)  
    					ELSE req.statement_END_offset
    					END
    					- req.statement_start_offset)/2) + 1)
    		, CHAR(10), ' '), CHAR(13), ' '), 1, 512)  AS active_statement_text 
    from sys.dm_exec_requests req
    	LEFT OUTER JOIN sys.dm_exec_connections conn on conn.session_id = req.session_id
		OUTER APPLY sys.dm_exec_sql_text (ISNULL (req.sql_handle, conn.most_recent_sql_handle)) as SQLText
		left outer join sys.dm_exec_sessions sess on conn.session_id = sess.session_id
		left outer join sys.dm_os_tasks tsk on sess.session_id = tsk.session_id  --including this to get task state (SPINLOOCK state is crucial)
    where sess.is_user_process = 1 
    and req.cpu_time > 60000
	--this is to prevent massive grants
    option (max_grant_percent = 3, MAXDOP 1)
    
	--flush results to client
	RAISERROR (' ', 0, 1) WITH NOWAIT
  END
END
GO

if object_id ('sp_run_highcpu_perfstats','p') is not null
   drop procedure sp_Run_HighCPU_PerfStats
go
create procedure sp_Run_HighCPU_PerfStats 
as

  -- Main loop

print 'starting high cpu perf stats script...'
set language us_english
print '-- script source --'
select 'high cpu perf stats script' as script_name, '$revision: 16 $ ($change: ? $)' as revision
print ''
print '-- script and environment details --'
print 'name                     value'
print '------------------------ ---------------------------------------------------'
print 'sql server name          ' + @@servername
print 'machine name             ' + convert (varchar, serverproperty ('machinename'))
print 'sql version (sp)         ' + convert (varchar, serverproperty ('productversion')) + ' (' + convert (varchar, serverproperty ('productlevel')) + ')'
print 'edition                  ' + convert (varchar, serverproperty ('edition'))
print 'script name              sql server perf stats script'
print 'script file name         $file: highcpu_perfstats.sql $'
print 'revision                 $revision: 16 $ ($change: ? $)'
print 'last modified            $date: 2019/11/16  $'
print 'script begin time        ' + convert (varchar(30), getdate(), 126) 
print 'current database         ' + db_name()
print '@@spid                   ' + ltrim(str(@@spid))
print ''


DECLARE @runtime datetime, @runtime_utc datetime, @prevruntime datetime
DECLARE @msg varchar(100)


SELECT @prevruntime = sqlserver_start_time from sys.dm_os_sys_info

--set prevtime to 5 min earlier, in case SQL just started
SET @prevruntime = DATEADD(SECOND, -300, @prevruntime)




  WHILE (1=1)
  BEGIN
    SET @runtime = GETDATE()
	SET @runtime_utc = GETUTCDATE()
    SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)

    PRINT ''
    RAISERROR (@msg, 0, 1) WITH NOWAIT
  
  	
    -- Collect sp_perf_high_Cpu_snapshot every 3 minutes
	exec sp_perf_high_cpu_snapshots 'pssdiag', @runtime = @runtime, @runtime_utc = @runtime_utc
	SET @prevruntime = @runtime
	
	
    WAITFOR DELAY '0:00:30'

	
  END
GO


exec sp_Run_HighCPU_PerfStats

