set nocount on
go
print '';
RAISERROR ('-- DiagInfo --', 0, 1) WITH NOWAIT;
select 1001 as 'DiagVersion', '2015-01-09' as 'DiagDate'
print ''
go
print 'Script Version = 1001'
print ''
create table #summary (PropertyName nvarchar(50) primary key, PropertyValue nvarchar(256))
insert into #summary values ('ProductVersion', cast (SERVERPROPERTY('ProductVersion') as nvarchar(max)))
insert into #summary values ('MajorVersion', LEFT(CONVERT(SYSNAME,SERVERPROPERTY('ProductVersion')), CHARINDEX('.', CONVERT(SYSNAME,SERVERPROPERTY('ProductVersion')), 0)-1))
insert into #summary values ('IsClustered', cast (SERVERPROPERTY('IsClustered') as nvarchar(max)))
insert into #summary values ('Edition', cast (SERVERPROPERTY('Edition') as nvarchar(max)))
insert into #summary values ('InstanceName', cast (SERVERPROPERTY('InstanceName') as nvarchar(max)))
insert into #summary values ('SQLServerName', @@SERVERNAME)
insert into #summary values ('MachineName', cast (SERVERPROPERTY('MachineName') as nvarchar(max)))
insert into #summary values ('ProcessID', cast (SERVERPROPERTY('ProcessID') as nvarchar(max)))
insert into #summary values ('ResourceVersion', cast (SERVERPROPERTY('ResourceVersion') as nvarchar(max)))
insert into #summary values ('ServerName', cast (SERVERPROPERTY('ServerName') as nvarchar(max)))
insert into #summary values ('ComputerNamePhysicalNetBIOS', cast (SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as nvarchar(max)))
insert into #summary values ('BuildClrVersion', cast (SERVERPROPERTY('BuildClrVersion') as nvarchar(max)))
insert into #summary values ('IsFullTextInstalled', cast (SERVERPROPERTY('IsFullTextInstalled') as nvarchar(max)))
insert into #summary values ('IsIntegratedSecurityOnly', cast (SERVERPROPERTY('IsIntegratedSecurityOnly') as nvarchar(max)))
insert into #summary values ('ProductLevel', cast (SERVERPROPERTY('ProductLevel') as nvarchar(max)))

insert into #summary select 'number of visible schedulers', count (*) 'cnt' from sys.dm_os_schedulers where status = 'VISIBLE ONLINE'
insert into #summary select 'number of visible numa nodes', count (distinct parent_node_id) 'cnt' from sys.dm_os_schedulers where status = 'VISIBLE ONLINE'
insert into #summary select 'cpu_count', cpu_count from sys.dm_os_sys_info
insert into #summary select 'hyperthread_ratio', hyperthread_ratio from sys.dm_os_sys_info
insert into #summary select 'machine start time', convert(varchar(23),dateadd(SECOND, -ms_ticks/1000, GETDATE()),121) from sys.dm_os_sys_info
insert into #summary values ('FilestreamShareName', cast (SERVERPROPERTY('FilestreamShareName') as nvarchar(max)))
insert into #summary values ('FilestreamConfiguredLevel', cast (SERVERPROPERTY('FilestreamConfiguredLevel') as nvarchar(max)))
insert into #summary values ('FilestreamEffectiveLevel', cast (SERVERPROPERTY('FilestreamEffectiveLevel') as nvarchar(max)))
exec sp_executesql N'insert into #summary select ''physical_memory_kb'', physical_memory_kb from sys.dm_os_sys_info'
insert into #summary values ('HadrManagerStatus', cast (SERVERPROPERTY('HadrManagerStatus') as nvarchar(max)))
insert into #summary values ('IsHadrEnabled', cast (SERVERPROPERTY('IsHadrEnabled') as nvarchar(max)))	
insert into #summary values ('IsLocalDB', cast (SERVERPROPERTY('IsLocalDB') as nvarchar(max)))
insert into #summary values ('IsXTPSupported', cast (SERVERPROPERTY('IsXTPSupported') as nvarchar(max)))

RAISERROR ('--ServerProperty--', 0, 1) WITH NOWAIT
select * from #summary
order by PropertyName
drop table #summary
go

-- commented out by Suresh Kandoth since this will hang 
-- declare @startup table (ArgsName nvarchar(10), ArgsValue nvarchar(max))
-- insert into @startup EXEC master..xp_instance_regenumvalues 'HKEY_LOCAL_MACHINE',   'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\Parameters'
-- print ''
-- RAISERROR ('--Startup Parameters--', 0, 1) WITH NOWAIT
-- select * from @startup
-- go

create table #traceflg (TraceFlag int, Status int, Global int, Session int)
insert into #traceflg exec ('dbcc tracestatus (-1)')
print ''
RAISERROR ('--traceflags--', 0, 1) WITH NOWAIT
select * from #traceflg
drop table #traceflg
go



--SET NOCOUNT ON
DECLARE @runtime datetime 
DECLARE @cpu_time_start bigint, @cpu_time bigint, @elapsed_time_start bigint, @rowcount bigint
DECLARE @queryduration int, @qrydurationwarnthreshold int
DECLARE @querystarttime datetime
SET @runtime = GETDATE()
SET @qrydurationwarnthreshold = 5000

PRINT ''
PRINT ''
PRINT ''
PRINT 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
PRINT ''
PRINT '==============================================================================================='
PRINT 'Top N Query Plan Statistics: '
PRINT 'For certain workloads, the sys.dm_exec_query_stats DMV can be a very useful way to identify '
PRINT 'the most expensive queries without a profiler trace. The query output below shows the top 50 '
PRINT 'query plans by CPU, physical reads, and total query execution time. However, be cautious of '
PRINT 'relying on this DMV alone, as it has some sigificant limitations. In particular: '
PRINT ' - This query provides a view of query plans in the procedure cache. However, not every query '
PRINT '   plan will be inserted into the cache. For example, a DBCC DBREINDEX might be an extremely '
PRINT '   expensive operation, but the plan for this query will not be cached, and its execution '
PRINT '   statistics will therefore not be reflected by this query. '
PRINT ' - A plan can be removed from cache at any time. The sys.dm_exec_query_stats DMV can only show ' 
PRINT '   statistics for plans that are still in cache.'
PRINT ' - The statistics exposed by sys.dm_exec_query_stats are cumulative for the lifetime for the '
PRINT '   query plan, but not all plans in cache have the same lifetime. For example, the query plan '
PRINT '   that is the most expensive right now might not appear to be the most expensive if it has '
PRINT '   only been in cache for a short period. Another query plan that is less expensive over any '
PRINT '   given period of time might seem more expensive because its statistics have been '
PRINT '   accumulating for a longer period. '
PRINT ' - Execution statistics are only recorded in the DMV at the end of query execution. Thge DMV '
PRINT '   may not reflect the execution cost for a long-running query that is still in-progress. ' 
PRINT ' - sys.dm_exec_query_stats only reflects the cost of query execution. Query compilation, plan ' 
PRINT '   lookup, and other pre-execution costs are not reflected in statistics.' 
PRINT ' - Any query plan that contains inline literals and is not explicitly or implicitly ' 
PRINT '   parameterized will not be reused. Every execution of this query with different parameter '
PRINT '   values will get a new compiled plan. If a query does not see consistent plan reuse, the '
PRINT '   sys.dm_exec_query_stats DMV will not show the cumulative cost of that query in a single row.'
PRINT ''
PRINT '-- Top N Query Plan Statistics --'
SELECT @cpu_time_start = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID
SET @querystarttime = GETDATE()
SELECT 
  CONVERT (varchar(30), @runtime, 126) AS 'runtime', 
  LEFT (p.cacheobjtype + ' (' + p.objtype + ')', 35) AS 'cacheobjtype',
  p.usecounts, p.size_in_bytes / 1024 AS 'size_in_kb', 
  PlanStats.total_worker_time/1000 AS 'tot_cpu_ms', PlanStats.total_elapsed_time/1000 AS 'tot_duration_ms', 
  PlanStats.total_physical_reads, PlanStats.total_logical_writes, PlanStats.total_logical_reads,
  PlanStats.CpuRank, PlanStats.PhysicalReadsRank, PlanStats.DurationRank, 
  LEFT (CASE 
    WHEN pa.value=32767 THEN 'ResourceDb' 
    ELSE ISNULL (DB_NAME (CONVERT (sysname, pa.value)), CONVERT (sysname,pa.value))
  END, 40) AS 'dbname',
  sql.objectid, 
  CONVERT (nvarchar(50), CASE 
    WHEN sql.objectid IS NULL THEN NULL 
    ELSE REPLACE (REPLACE (sql.[text],CHAR(13), ' '), CHAR(10), ' ')
  END) AS 'procname', 
  REPLACE (REPLACE (SUBSTRING (sql.[text], PlanStats.statement_start_offset/2 + 1, 
      CASE WHEN PlanStats.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), sql.[text])) 
        ELSE PlanStats.statement_end_offset/2 - PlanStats.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' ') AS 'stmt_text' 
  ,PlanStats.query_hash, PlanStats.query_plan_hash, PlanStats.creation_time, PlanStats.statement_start_offset, PlanStats.statement_end_offset, PlanStats.plan_generation_num,
  PlanStats.min_worker_time, PlanStats.last_worker_time, PlanStats.max_worker_time,
  PlanStats.min_elapsed_time, PlanStats.last_elapsed_time, PlanStats.max_elapsed_time,
  PlanStats.min_physical_reads, PlanStats.last_physical_reads, PlanStats.max_physical_reads, 
  PlanStats.min_logical_writes, PlanStats.last_logical_writes, PlanStats.max_logical_writes, 
  PlanStats.min_logical_reads, PlanStats.last_logical_reads, PlanStats.max_logical_reads,
  PlanStats.plan_handle
FROM 
(
  SELECT 
    stat.plan_handle, statement_start_offset, statement_end_offset, 
    stat.total_worker_time, stat.total_elapsed_time, stat.total_physical_reads, 
    stat.total_logical_writes, stat.total_logical_reads,
	stat.query_hash, stat.query_plan_hash, stat.plan_generation_num, stat.creation_time, 
	stat.last_worker_time, stat.min_worker_time, stat.max_worker_time, stat.last_elapsed_time, stat.min_elapsed_time, stat.max_elapsed_time,
	stat.last_physical_reads, stat.min_physical_reads, stat.max_physical_reads, stat.last_logical_writes, stat.min_logical_writes, stat.max_logical_writes, stat.last_logical_reads, stat.min_logical_reads, stat.max_logical_reads,
    ROW_NUMBER() OVER (ORDER BY stat.total_worker_time DESC) AS CpuRank, 
    ROW_NUMBER() OVER (ORDER BY stat.total_physical_reads DESC) AS PhysicalReadsRank, 
    ROW_NUMBER() OVER (ORDER BY stat.total_elapsed_time DESC) AS DurationRank 
  FROM sys.dm_exec_query_stats stat 
) AS PlanStats 
INNER JOIN sys.dm_exec_cached_plans p ON p.plan_handle = PlanStats.plan_handle 
OUTER APPLY sys.dm_exec_plan_attributes (p.plan_handle) pa 
OUTER APPLY sys.dm_exec_sql_text (p.plan_handle) AS sql
WHERE (PlanStats.CpuRank < 50 OR PlanStats.PhysicalReadsRank < 50 OR PlanStats.DurationRank < 50)
  AND pa.attribute = 'dbid' 
ORDER BY tot_cpu_ms DESC

SET @rowcount = @@ROWCOUNT
SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
IF @queryduration > @qrydurationwarnthreshold
BEGIN
  SELECT @cpu_time = cpu_time - @cpu_time_start FROM sys.dm_exec_sessions WHERE session_id = @@SPID
  PRINT ''
  PRINT 'DebugPrint: perfstats_snapshot_querystats - ' + CONVERT (varchar, @queryduration) + 'ms, ' 
    + CONVERT (varchar, @cpu_time) + 'ms cpu, '
    + 'rowcount=' + CONVERT(varchar, @rowcount) 
  PRINT ''
END


PRINT ''
PRINT '==============================================================================================='
PRINT 'Missing Indexes: '
PRINT 'The "improvement_measure" column is an indicator of the (estimated) improvement that might '
PRINT 'be seen if the index was created.  This is a unitless number, and has meaning only relative '
PRINT 'the same number for other indexes.  The measure is a combination of the avg_total_user_cost, '
PRINT 'avg_user_impact, user_seeks, and user_scans columns in sys.dm_db_missing_index_group_stats.'
PRINT ''
PRINT '-- Missing Indexes --'
SELECT CONVERT (varchar(30), @runtime, 126) AS runtime, 
  mig.index_group_handle, mid.index_handle, 
  CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS improvement_measure, 
  'CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle) 
  + ' ON ' + mid.statement 
  + ' (' + ISNULL (mid.equality_columns,'') 
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '')
  + ')' 
  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement, 
  migs.*, mid.database_id, mid.[object_id]
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) > 10
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC
PRINT ''
GO

PRINT ''
PRINT '-- Current database options --'
SELECT LEFT ([name], 128) AS [name], 
  dbid, cmptlevel, 
  CONVERT (int, (SELECT SUM (CONVERT (bigint, [size])) * 8192 / 1024 / 1024 FROM master.dbo.sysaltfiles f WHERE f.dbid = d.dbid)) AS db_size_in_mb, 
  LEFT (
  'Status=' + CONVERT (sysname, DATABASEPROPERTYEX ([name],'Status')) 
  + ', Updateability=' + CONVERT (sysname, DATABASEPROPERTYEX ([name],'Updateability')) 
  + ', UserAccess=' + CONVERT (varchar(40), DATABASEPROPERTYEX ([name], 'UserAccess')) 
  + ', Recovery=' + CONVERT (varchar(40), DATABASEPROPERTYEX ([name], 'Recovery')) 
  + ', Version=' + CONVERT (varchar(40), DATABASEPROPERTYEX ([name], 'Version')) 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAutoCreateStatistics') = 1 THEN ', IsAutoCreateStatistics' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAutoUpdateStatistics') = 1 THEN ', IsAutoUpdateStatistics' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsShutdown') = 1 THEN '' ELSE ', Collation=' + CONVERT (varchar(40), DATABASEPROPERTYEX ([name], 'Collation'))  END
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAutoClose') = 1 THEN ', IsAutoClose' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAutoShrink') = 1 THEN ', IsAutoShrink' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsInStandby') = 1 THEN ', IsInStandby' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsTornPageDetectionEnabled') = 1 THEN ', IsTornPageDetectionEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAnsiNullDefault') = 1 THEN ', IsAnsiNullDefault' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAnsiNullsEnabled') = 1 THEN ', IsAnsiNullsEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAnsiPaddingEnabled') = 1 THEN ', IsAnsiPaddingEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsAnsiWarningsEnabled') = 1 THEN ', IsAnsiWarningsEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsArithmeticAbortEnabled') = 1 THEN ', IsArithmeticAbortEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsCloseCursorsOnCommitEnabled') = 1 THEN ', IsCloseCursorsOnCommitEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsFullTextEnabled') = 1 THEN ', IsFullTextEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsLocalCursorsDefault') = 1 THEN ', IsLocalCursorsDefault' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsNumericRoundAbortEnabled') = 1 THEN ', IsNumericRoundAbortEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsQuotedIdentifiersEnabled') = 1 THEN ', IsQuotedIdentifiersEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsRecursiveTriggersEnabled') = 1 THEN ', IsRecursiveTriggersEnabled' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsMergePublished') = 1 THEN ', IsMergePublished' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsPublished') = 1 THEN ', IsPublished' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsSubscribed') = 1 THEN ', IsSubscribed' ELSE '' END 
  + CASE WHEN DATABASEPROPERTYEX ([name], 'IsSyncWithBackup') = 1 THEN ', IsSyncWithBackup' ELSE '' END
  , 512) AS status
FROM master.dbo.sysdatabases d
GO



PRINT 'End time: ' + CONVERT (varchar, GETDATE(), 126)
PRINT 'Done.'
GO

print 'getting resource governor info'
print '=========================================='
go
print 'sys.resource_governor_configuration'
select * from sys.resource_governor_configuration
go
print 'sys.resource_governor_resource_pools'
select * from sys.resource_governor_resource_pools
go
print 'sys.resource_governor_workload_groups'
select * from sys.resource_governor_workload_groups
go




print '--sys.dm_database_encryption_keys  Transparent Database Encryption (TDE) information'
select DB_NAME(database_id) as 'database_name', * from sys.dm_database_encryption_keys 
go
print '-- sys.dm_os_loaded_modules '
select * from sys.dm_os_loaded_modules

go
print '--sys.dm_server_audit_status'
select * from sys.dm_server_audit_status

go

print '--top 10 CPU consuming procedures '
SELECT TOP 10 d.object_id, d.database_id, db_name(database_id) 'db name', object_name (object_id, database_id) 'proc name',  d.cached_time, d.last_execution_time, d.total_elapsed_time, d.total_elapsed_time/d.execution_count AS [avg_elapsed_time], d.last_elapsed_time, d.execution_count
from sys.dm_exec_procedure_stats d
ORDER BY [total_worker_time] DESC;
GO


print '--top 10 CPU consuming triggers '
SELECT TOP 10 d.object_id, d.database_id, db_name(database_id) 'db name', object_name (object_id, database_id) 'proc name',  d.cached_time, d.last_execution_time, d.total_elapsed_time, d.total_elapsed_time/d.execution_count AS [avg_elapsed_time], d.last_elapsed_time, d.execution_count
from sys.dm_exec_trigger_stats d
ORDER BY [total_worker_time] DESC;
GO





print '-- query and plan hash capture --'
print '-- query and plan hash capture --'
print '-- top 10 CPU by query_hash --'
select getdate() as runtime, *  --into tbl_QueryHashByCPU
from
(
SELECT TOP 10 query_hash, COUNT (distinct query_plan_hash) as 'distinct query_plan_hash count',
	 sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
	 
    max(REPLACE (REPLACE (SUBSTRING (st.[text], qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), st.[text])) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_hash
ORDER BY sum(total_worker_time) DESC
) t

go


print '-- top 10 logical reads by query_hash --'
select getdate() as runtime, *  --into tbl_QueryHashByLogicalReads
from
(
SELECT TOP 10 query_hash, 
	COUNT (distinct query_plan_hash) as 'distinct query_plan_hash count',
	sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE (REPLACE (SUBSTRING (st.[text], qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), st.[text])) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_hash
ORDER BY sum(total_logical_reads) DESC
) t
go

print '-- top 10 elapsed time by query_hash --'
select getdate() as runtime, * -- into tbl_QueryHashByElapsedTime
from
(
SELECT TOP 10 query_hash, 
	sum(execution_count) as 'execution_count', 
	COUNT (distinct query_plan_hash) as 'distinct query_plan_hash count',
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE (REPLACE (SUBSTRING (st.[text], qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), st.[text])) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_hash
ORDER BY sum(total_elapsed_time) DESC
) t
go


print '-- top 10 CPU by query_plan_hash and query_hash --'
SELECT TOP 10 query_plan_hash, query_hash, 
COUNT (distinct query_plan_hash) as 'distinct query_plan_hash count',
sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE (REPLACE (SUBSTRING (st.[text], qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), st.[text])) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_plan_hash, query_hash
ORDER BY sum(total_worker_time) DESC;

go


print '-- top 10 logical reads by query_plan_hash and query_hash --'
SELECT TOP 10 query_plan_hash, query_hash, sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE (REPLACE (SUBSTRING (st.[text], qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), st.[text])) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_plan_hash, query_hash
ORDER BY sum(total_logical_reads) DESC;

go


print '-- top 10 elapsed time  by query_plan_hash and query_hash --'
SELECT TOP 10 query_plan_hash, query_hash, sum(execution_count) as 'execution_count', 
	 sum(total_worker_time) as 'total_worker_time',
	 SUM(total_elapsed_time) as 'total_elapsed_time',
	 SUM (total_logical_reads) as 'total_logical_reads',
    max(REPLACE (REPLACE (SUBSTRING (st.[text], qs.statement_start_offset/2 + 1, 
      CASE WHEN qs.statement_end_offset = -1 THEN LEN (CONVERT(nvarchar(max), st.[text])) 
        ELSE qs.statement_end_offset/2 - qs.statement_start_offset/2 + 1
      END), CHAR(13), ' '), CHAR(10), ' '))  AS sample_statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
group by query_plan_hash, query_hash
ORDER BY sum(total_elapsed_time) DESC;

go

PRINT ''
RAISERROR ('-- new row modification counter --', 0, 1) WITH NOWAIT;
--this only is available after SQL 2008 R2 SP2 and SQL 2012 SP1 and SQL 2014
if (@@MICROSOFTVERSION >= 171052960 and @@MICROSOFTVERSION < 184551476) OR  (@@MICROSOFTVERSION >= 184551476 )
begin

	EXEC master..sp_MSforeachdb @command1 = '
	PRINT ''''
	PRINT ''-- sys.dm_db_stats_properties for database name [?]  database id: '' + cast (db_id (''?'') as varchar(20))  + '' --''', 
	  @command2 = '
	use [?]
	SELECT db_name() ''database_name'', 
	object_name (stat.object_id) ''Object_Name'', stat.object_id,
		sp.stats_id, name, filter_definition, cast(last_updated as datetime) ''last_updated'', rows, rows_sampled, steps, unfiltered_rows, modification_counter 
	FROM sys.stats AS stat 
	CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
	'

end
go

print '--hadron replica info--'
SELECT 
      ag.name AS ag_name, 
      ar.replica_server_name  ,
      ar_state.is_local AS is_ag_replica_local, 
      ag_replica_role_desc = 
            CASE 
                  WHEN ar_state.role_desc IS NULL THEN N'<unknown>'
                  ELSE ar_state.role_desc 
            END, 
      ag_replica_operational_state_desc = 
            CASE 
                  WHEN ar_state.operational_state_desc IS NULL THEN N'<unknown>'
                  ELSE ar_state.operational_state_desc 
            END, 
      ag_replica_connected_state_desc = 
            CASE 
                  WHEN ar_state.connected_state_desc IS NULL THEN 
                        CASE 
                              WHEN ar_state.is_local = 1 THEN N'CONNECTED'
                              ELSE N'<unknown>'
                        END
                  ELSE ar_state.connected_state_desc 
            END
     
FROM 

      sys.availability_groups AS ag 
      JOIN sys.availability_replicas AS ar 
      ON ag.group_id = ar.group_id
	  JOIN sys.dm_hadr_availability_replica_states AS ar_state 
		ON  ar.replica_id = ar_state.replica_id;
go
print ''
print '-- sys.availability_groups --'
select * from sys.availability_groups
go


print ''
RAISERROR ('--sys.dm_hadr_availability_group_states--', 0, 1) WITH NOWAIT
select * from sys.dm_hadr_availability_group_states
go
print ''
RAISERROR ('--sys.dm_hadr_availability_replica_states--', 0, 1) WITH NOWAIT
select * from sys.dm_hadr_availability_replica_states
go
print ''
RAISERROR ('--sys.availability_replicas--', 0, 1) WITH NOWAIT
select * from sys.availability_replicas

print ''
print '-- sys.dm_hadr_cluster --'
select * from sys.dm_hadr_cluster
go
print ''
print '-- sys.dm_hadr_cluster_members --'
select * from sys.dm_hadr_cluster_members
go

print ''
print '-- sys.dm_hadr_cluster_networks --'
select * from sys.dm_hadr_cluster_networks
go

print ''
RAISERROR ('--sys.dm_hadr_database_replica_cluster_states--', 0, 1) WITH NOWAIT
select * from sys.dm_hadr_database_replica_cluster_states
go

	--new stats DMV
	set nocount on
	declare @dbname sysname, @dbid int
	DECLARE dbCursor CURSOR FOR 
	select name, database_id from sys.databases where state_desc='ONLINE' and database_id > 4 order by name
	OPEN dbCursor

	FETCH NEXT FROM dbCursor  INTO @dbname, @dbid
	select @dbid 'Database_Id', @dbname 'Database_Name',  Object_name(st.object_id) 'Object_Name',  st.* into #tmpStats from sys.dm_db_index_usage_stats usg cross apply sys.dm_db_stats_properties (usg.object_id, index_id) st where database_id is null
	WHILE @@FETCH_STATUS = 0
	begin
	
		declare @sql nvarchar (512)
		set @sql = 'USE ' + @dbname
	
		set @sql = @sql + '	insert into #tmpStats	select ' + cast( @dbid as nvarchar(20)) +   ' ''Database_Id''' + ',''' +  @dbname  + ''' Database_Name,  Object_name(st.object_id) ''Object_Name'',  st.* from sys.dm_db_index_usage_stats usg cross apply sys.dm_db_stats_properties (usg.object_id, index_id) st where database_id  = ' + cast( @dbid as nvarchar(20)) 
	
		exec (@sql)
		--print @sql
		FETCH NEXT FROM dbCursor  INTO @dbname, @dbid

	end
	close  dbCursor
	deallocate dbCursor
	print ''
	print '--sys.dm_db_stats_properties--'
	select * from #tmpStats order by database_name
	drop table #tmpStats
	print ''


	--disable indexes

	set nocount on
	declare @dbname_index sysname, @dbid_index int
	DECLARE dbCursor_Index CURSOR FOR 
	select name, database_id from sys.databases where state_desc='ONLINE' and database_id > 4 order by name
	OPEN dbCursor_Index

	FETCH NEXT FROM dbCursor_Index  INTO @dbname_index, @dbid_index
	select db_id() 'database_id', db_name() 'database_name', object_name(object_id) 'object_name', * into #tblDisabledIndex from sys.indexes where is_disabled = 1 and 1=0

	WHILE @@FETCH_STATUS = 0
	begin
	
		declare @sql_index nvarchar (512)
		set @sql_index = 'USE ' + @dbname_index
	
		set @sql_index = @sql_index + '	insert into #tblDisabledIndex	select  db_id()  database_id, db_name() database_name, object_name(object_id) object_name, *  from sys.indexes where is_disabled = 1'
	
		exec (@sql_index)
		--print @sql
		FETCH NEXT FROM dbCursor_Index  INTO @dbname_index, @dbid_index

	end
	close  dbCursor_Index
	deallocate dbCursor_Index
	print ''
	print '--disabled indexes--'
	select * from #tblDisabledIndex order by database_name
	drop table #tblDisabledIndex
	print ''


	print ''
	RAISERROR ('--sys.configurations--', 0, 1) WITH NOWAIT
	select configuration_id, 
	  convert(int,value) as 'value', 
	  convert(int,value_in_use) as 'value_in_use', 
	  convert(int,minimum) as 'minimum', 
	  convert(int,maximum) as 'maximum', 
	  convert(int,is_dynamic) as 'is_dynamic', 
	  convert(int,is_advanced) as 'is_advanced', 
	  name  
	from sys.configurations order by name

print ''
RAISERROR ('--database files--', 0, 1) WITH NOWAIT
--select db_name(database_id) 'Database_name', * from master.sys.master_files order by database_id, type, file_id

select database_id, [file_id], file_guid, [type],  LEFT(type_desc,10) as 'type_desc', data_space_id, [state], LEFT(state_desc,16) as 'state_desc', size, max_size, growth,
  is_media_read_only, is_read_only, is_sparse, is_percent_growth, is_name_reserved, create_lsn,  drop_lsn, read_only_lsn, read_write_lsn, differential_base_lsn, differential_base_guid,
  differential_base_time, redo_start_lsn, redo_start_fork_guid, redo_target_lsn, redo_target_fork_guid, backup_lsn, db_name(database_id) as 'Database_name',  name, physical_name 
from master.sys.master_files order by database_id, type, file_id
go


print ''
print '--profiler trace summary--'
SELECT traceid, property, CONVERT (varchar(1024), value) AS value FROM :: fn_trace_getinfo(default)
go
print ''
print '--trace event details--'
      select trace_id,
            status,
            case when row_number = 1 then path else NULL end as path,
            case when row_number = 1 then max_size else NULL end as max_size,
            case when row_number = 1 then start_time else NULL end as start_time,
            case when row_number = 1 then stop_time else NULL end as stop_time,
            max_files, 
            is_rowset, 
            is_rollover,
            is_shutdown,
            is_default,
            buffer_count,
            buffer_size,
            last_event_time,
            event_count,
            trace_event_id, 
            trace_event_name, 
            trace_column_id,
            trace_column_name,
            expensive_event   
      from 
            (SELECT t.id AS trace_id, 
                  row_number() over (partition by t.id order by te.trace_event_id, tc.trace_column_id) as row_number, 
                  t.status, 
                  t.path, 
                  t.max_size, 
                  t.start_time,
                  t.stop_time, 
                  t.max_files, 
                  t.is_rowset, 
                  t.is_rollover,
                  t.is_shutdown,
                  t.is_default,
                  t.buffer_count,
                  t.buffer_size,
                  t.last_event_time,
                  t.event_count,
                  te.trace_event_id, 
                  te.name AS trace_event_name, 
                  tc.trace_column_id,
                  tc.name AS trace_column_name,
                  case when te.trace_event_id in (23, 24, 40, 41, 44, 45, 51, 52, 54, 68, 96, 97, 98, 113, 114, 122, 146, 180) then cast(1 as bit) else cast(0 as bit) end as expensive_event
            FROM sys.traces t 
                  CROSS apply ::fn_trace_geteventinfo(t .id) AS e 
                  JOIN sys.trace_events te ON te.trace_event_id = e.eventid 
                  JOIN sys.trace_columns tc ON e.columnid = trace_column_id) as x


go
print ''
print '--XEvent Session Details--'
select sess.name 'session_name', event_name  from sys.dm_xe_sessions sess join sys.dm_xe_session_events evt on sess.address = evt.event_session_address
print ''
go
