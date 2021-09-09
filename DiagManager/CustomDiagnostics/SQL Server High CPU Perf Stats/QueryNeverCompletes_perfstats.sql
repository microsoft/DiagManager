use tempdb
go
IF OBJECT_ID ('dbo.sp_perf_never_ending_query_snapshots','P') IS NOT NULL
   DROP PROCEDURE dbo.sp_perf_never_ending_query_snapshots
GO

CREATE PROCEDURE dbo.sp_perf_never_ending_query_snapshots @appname sysname='PSSDIAG'
AS
SET NOCOUNT ON

DECLARE @cpu_threshold_ms int = 60000

BEGIN
 DECLARE @msg varchar(100)

 IF EXISTS (SELECT * FROM sys.dm_exec_requests req left outer join sys.dm_exec_sessions sess
				on req.session_id = sess.session_id
				WHERE req.session_id <> @@SPID AND ISNULL (sess.host_name, '') != @appname and sess.is_user_process = 1 AND req.cpu_time > @cpu_threshold_ms) 
					
 BEGIN
    
	DECLARE @runtime datetime = GETDATE(), @runtime_utc datetime = GETUTCDATE()
    --SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
    RAISERROR (@msg, 0, 1) WITH NOWAIT

	
	PRINT ''
	RAISERROR ('-- neverending_query --', 0, 1) WITH NOWAIT

           --query the DMV in a loop to compare the 
        SELECT CONVERT (varchar(30), @runtime, 126) as runtime,
            CONVERT (varchar(30), @runtime_utc, 126) as runtime_utc,
            qp.session_id,
            text as query_text,
            qp.physical_operator_name,
            qp.node_id,
            qp.row_count,
            qp.rewind_count,
            qp.rebind_count, 
			qp.end_of_scan_count,
            qp.estimate_row_count,
            req.cpu_time,
            req.total_elapsed_time
        FROM sys.dm_exec_query_profiles qp 
		LEFT OUTER JOIN sys.dm_exec_requests req
			ON qp.session_id = req.session_id
		LEFT OUTER JOIN sys.dm_exec_sessions sess
			on req.session_id = sess.session_id
		CROSS APPLY sys.dm_exec_sql_text(qp.sql_handle) st
		WHERE req.session_id <> @@SPID 
			AND ISNULL (sess.host_name, '') != @appname 
			AND sess.is_user_process = 1 
			AND req.cpu_time > @cpu_threshold_ms 
        ORDER BY qp.node_id
		--this is to prevent massive grants
		OPTION (max_grant_percent = 3, MAXDOP 1)
    
	--flush results to client
	RAISERROR (' ', 0, 1) WITH NOWAIT

  END
END
GO



IF OBJECT_ID ('dbo.sp_Run_NeverEndingQuery_Stats','P') IS NOT NULL
   DROP PROCEDURE dbo.sp_Run_NeverEndingQuery_Stats
GO

CREATE PROCEDURE dbo.sp_Run_NeverEndingQuery_Stats
as
SET NOCOUNT ON

PRINT 'starting query never seems to complete perf stats script...'
set language us_english
PRINT '-- script source --'
select 'query never completes stats script' as script_name
PRINT ''
PRINT '-- script and environment details --'
PRINT 'name                     value'
PRINT '------------------------ ---------------------------------------------------'
PRINT 'sql server name          ' + @@servername
PRINT 'machine name             ' + convert (varchar, serverproperty ('machinename'))
PRINT 'sql version (sp)         ' + convert (varchar, serverproperty ('productversion')) + ' (' + convert (varchar, serverproperty ('productlevel')) + ')'
PRINT 'edition                  ' + convert (varchar, serverproperty ('edition'))
PRINT 'script name              Query Never Completes stats script'
PRINT 'script file name         $file: QueryNeverCompletes_perfstats.sql $'
PRINT 'last modified            $date: 2021/09/07  $'
PRINT 'script begin time        ' + convert (varchar(30), getdate(), 126) 
PRINT 'current database         ' + db_name()
PRINT '@@spid                   ' + ltrim(str(@@spid))


--handle SQL Server 2008 code line, thus need to parse ProductVersion
DECLARE @servermajorversion int
SET @servermajorversion = CONVERT (INT, (REPLACE (LEFT (CONVERT (nvarchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')))

if (@servermajorversion < 12)
begin
    RAISERROR ('Lightweight Profiling    SQL Server version is less than 2014. No additional data can be collected', 0, 1) WITH NOWAIT
	PRINT ''
    return
end

declare @serverbuild int
SET @serverbuild = CONVERT (int, SERVERPROPERTY ('ProductBuild'))




--minimum build 12.0.5000.0 , see https://docs.microsoft.com/en-us/sql/relational-databases/performance/query-profiling-infrastructure?view=sql-server-ver15
if (@servermajorversion <= 12 and @serverbuild < 5000)
begin
    RAISERROR ('Lightweight Profiling    Your SQL Sever version does not support collecting real-time perf stats on long-running query', 0, 1) WITH NOWAIT
	PRINT ''
end
--13.0.4001.0 (SP1)
else if ((@servermajorversion = '13' and @serverbuild <4001) or (@servermajorversion = 12 and @serverbuild >= 5000))
begin
	RAISERROR ('Lightweight Profiling    Using Lightweight Profiling Ver1 requires that you enable SET STATISTICS PROFILE ON in the same session where the query runs', 0, 1) WITH NOWAIT
	PRINT ''
	PRINT 'See https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-profiles-transact-sql#examples for more information'
	PRINT ''


end
else if ((@servermajorversion = '13' and @serverbuild >=4001) or @servermajorversion = '14')
begin
    RAISERROR ('Lightweight Profiling    SQL 2016 SP1+ or 2017. Using Lightweight Profiling Ver2', 0, 1) WITH NOWAIT
	PRINT ''
	PRINT 'Enabling TF 7412'
    DBCC TRACEON (7412, -1)

    WHILE (1=1)
	BEGIN
        --query the DMV in a loop to compare the 
		EXEC dbo.sp_perf_never_ending_query_snapshots @appname = 'PSSDIAG'
        WAITFOR DELAY '00:00:10'
    END

end
else if (@servermajorversion >= '15')
begin
    RAISERROR ('Lightweight Profiling    SQL 2019. Using Lightweight Profiling Ver3 (enabled by default)', 0, 1) WITH NOWAIT
	PRINT ''

	WHILE (1=1)
	BEGIN
        --query the DMV in a loop to compare the 
		EXEC dbo.sp_perf_never_ending_query_snapshots @appname = 'PSSDIAG'
        WAITFOR DELAY '00:00:10'
    END
end

go
exec dbo.sp_Run_NeverEndingQuery_Stats


-- We found a bug where after a few minutes sys.dm_exec_query_profiles  stops showing ouptut for a very long running query . Or otherwise, we have to explicitly specify a session_id
--select * FROM sys.dm_exec_query_profiles qp 
--where session_id = 59
--Test 2016 2017 and 2019 to make sure it is consistent


	--TODO:
	-- ALSO RUN BATCH SCRIPT TO GET PLANS 
