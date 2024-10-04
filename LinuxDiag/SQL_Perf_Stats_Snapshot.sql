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

/*******************************************************************
perf stats snapshot

********************************************************************/
use tempdb
go
IF OBJECT_ID ('#sp_perf_stats_snapshot','P') IS NOT NULL
   DROP PROCEDURE #sp_perf_stats_snapshot
GO

CREATE PROCEDURE #sp_perf_stats_snapshot  
as
begin
	BEGIN TRY

		PRINT 'Starting SQL Server Perf Stats Snapshot Script...'
		PRINT 'SQL Version (SP)         ' + CONVERT (varchar, SERVERPROPERTY ('ProductVersion')) + ' (' + CONVERT (varchar, SERVERPROPERTY ('ProductLevel')) + ')'
		DECLARE @runtime datetime 
		DECLARE @cpu_time_start bigint, @cpu_time bigint, @elapsed_time_start bigint, @rowcount bigint
		DECLARE @queryduration int, @qrydurationwarnthreshold int
		DECLARE @querystarttime datetime
		SET @runtime = GETDATE()
		SET @qrydurationwarnthreshold = 5000

		PRINT ''
		PRINT 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
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
		OPTION (MAX_GRANT_PERCENT = 3, MAXDOP 1)

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
		OPTION (MAX_GRANT_PERCENT = 3, MAXDOP 1)

		PRINT ''
		PRINT ''

		PRINT '-- Current database options --'
		SELECT LEFT ([name], 128) AS [name], 
		dbid, cmptlevel, 
		CONVERT (int, (SELECT SUM (CONVERT (bigint, [size])) * 8192 / 1024 / 1024 FROM master.sys.master_files f WHERE f.database_id = d.dbid)) AS db_size_in_mb, 
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
		PRINT ''
		
		print '-- sys.dm_database_encryption_keys TDE --'
		declare @sql_major_version INT, @sql_major_build INT, @sql nvarchar (max)
		SELECT @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 4) AS INT)), 
			@sql_major_build = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 2) AS INT)) 
		set @sql = 'select DB_NAME(database_id) as ''database_name'', 
					[database_id]
					,[encryption_state]
					,[create_date]
					,[regenerate_date]
					,[modify_date]
					,[set_date]
					,[opened_date]
					,[key_algorithm]
					,[key_length]
					,[encryptor_thumbprint]
					,[percent_complete]'

		IF (@sql_major_version >=11)
		BEGIN	   
		set @sql = @sql + ',[encryptor_type]'
		END
		
		IF (@sql_major_version >=15)
		BEGIN	   
		set @sql = @sql + '[encryption_state_desc]
							,[encryption_scan_state]
							,[encryption_scan_state_desc]
							,[encryption_scan_modify_date]'
		END

		set @sql = @sql + ' from sys.dm_database_encryption_keys '
		
		--print @sql
		exec (@sql)
		
		PRINT ''

		

		print '-- sys.dm_server_audit_status --'
		select  
			audit_id,
			[name],
			[status],
			status_desc,
			status_time,
			event_session_address,
			audit_file_path,
			audit_file_size
		from sys.dm_server_audit_status
		print ''

		print '-- top 10 CPU consuming procedures --'
		SELECT TOP 10 getdate() as runtime, d.object_id, d.database_id, db_name(database_id) 'db name', object_name (object_id, database_id) 'proc name',  d.cached_time, d.last_execution_time, d.total_elapsed_time, d.total_elapsed_time/d.execution_count AS [avg_elapsed_time], d.last_elapsed_time, d.execution_count
		from sys.dm_exec_procedure_stats d
		ORDER BY [total_worker_time] DESC
		print ''

		print '-- top 10 CPU consuming triggers --'
		SELECT TOP 10 getdate() as runtime, d.object_id, d.database_id, db_name(database_id) 'db name', object_name (object_id, database_id) 'proc name',  d.cached_time, d.last_execution_time, d.total_elapsed_time, d.total_elapsed_time/d.execution_count AS [avg_elapsed_time], d.last_elapsed_time, d.execution_count
		from sys.dm_exec_trigger_stats d
		ORDER BY [total_worker_time] DESC
		print ''

		--new stats DMV
		set nocount on
		declare @dbname sysname, @dbid int

		SELECT @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 4) AS INT)), 
			@sql_major_build = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 2) AS INT)) 
		
		
		DECLARE dbCursor CURSOR FOR 
		select name, database_id from sys.databases where state_desc='ONLINE' and name not in ('model','tempdb') order by name
		OPEN dbCursor

		FETCH NEXT FROM dbCursor  INTO @dbname, @dbid
		
		--replaced sys.dm_db_index_usage_stats  by sys.stat since the first doesn't return anything in case the table or index was not accessed since last SQL restart
		select @dbid 'Database_Id', @dbname 'Database_Name',  Object_name(st.object_id) 'Object_Name', SCHEMA_NAME(schema_id) 'Schema_Name', ss.name 'Statistics_Name', 
				st.object_id, st.stats_id, st.last_updated, st.rows, st.rows_sampled, st.steps, st.unfiltered_rows, st.modification_counter
		into #tmpStats 
		from sys.stats ss cross apply sys.dm_db_stats_properties (ss.object_id, ss.stats_id) st inner join sys.objects so ON (ss.object_id = so.object_id) where 1=0
		
		--column st.persisted_sample_percent was only introduced on sys.dm_db_stats_properties on SQL Server 2016 (13.x) SP1 CU4 -- 13.0.4446.0 and 2017 CU1 14.0.3006.16	 
		IF (@sql_major_version >14 OR (@sql_major_version=13 AND @sql_major_build>=4446) OR (@sql_major_version=14 AND @sql_major_build>=3006))
		BEGIN
			ALTER TABLE #tmpStats ADD persisted_sample_percent FLOAT
		END

		WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN TRY
			
				set @sql = 'USE [' + @dbname + ']'
				--replaced sys.dm_db_index_usage_stats  by sys.stat since the first doesn't return anything in case the table or index was not accessed since last SQL restart
				IF (@sql_major_version >14 OR (@sql_major_version=13 AND @sql_major_build>=4446) OR (@sql_major_version=14 AND @sql_major_build>=3006))
				BEGIN
					set @sql = @sql + '	insert into #tmpStats	select ' + cast( @dbid as nvarchar(20)) +   ' ''Database_Id''' + ',''' +  @dbname  + ''' Database_Name,  Object_name(st.object_id) ''Object_Name'', SCHEMA_NAME(schema_id) ''Schema_Name'', ss.name ''Statistics_Name'', 
																		st.object_id, st.stats_id, st.last_updated, st.rows, st.rows_sampled, st.steps, st.unfiltered_rows, st.modification_counter, st.persisted_sample_percent
																from sys.stats ss 
																	cross apply sys.dm_db_stats_properties (ss.object_id, ss.stats_id) st 
																	inner join sys.objects so ON (ss.object_id = so.object_id)
																where so.type not in (''S'', ''IT'')'
				END
				ELSE
				BEGIN

				set @sql = @sql + '	insert into #tmpStats	select ' + cast( @dbid as nvarchar(20)) +   ' ''Database_Id''' + ',''' +  @dbname  + ''' Database_Name,  Object_name(st.object_id) ''Object_Name'', SCHEMA_NAME(schema_id) ''Schema_Name'', ss.name ''Statistics_Name'', 
																		st.object_id, st.stats_id, st.last_updated, st.rows, st.rows_sampled, st.steps, st.unfiltered_rows, st.modification_counter
																from sys.stats ss 
																cross apply sys.dm_db_stats_properties (ss.object_id, ss.stats_id) st 
																inner join sys.objects so ON (ss.object_id = so.object_id)
																where so.type not in (''S'', ''IT'')'
				
				END
				
				-- added this check to prevent script from failing on principals with restricted access
				if HAS_PERMS_BY_NAME(@dbname, 'DATABASE', 'CONNECT') = 1
					
					exec (@sql)
				else
					PRINT 'Skipped index usage and stats properties check. Principal ' + SUSER_SNAME() + ' does not have CONNECT permission on database ' + @dbname
				--print @sql
				FETCH NEXT FROM dbCursor  INTO @dbname, @dbid
			END TRY
			BEGIN CATCH
				PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
				PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
			END CATCH
		END
		close  dbCursor
		deallocate dbCursor
		print ''
		print '-- sys.dm_db_stats_properties --'
		declare @sql2 nvarchar (max)

		IF (@sql_major_version >14 OR (@sql_major_version=13 AND @sql_major_build>=4446) OR (@sql_major_version=14 AND @sql_major_build>=3006))
		BEGIN
			set @sql2 = 'select --*
							Database_Id,
							[Database_Name],
							[Schema_Name],
							[Object_Name],
							[object_id],
							[stats_id],
							[Statistics_Name],
							[last_updated],
							[rows],
							rows_sampled,
							steps,
							unfiltered_rows,
							modification_counter,
							persisted_sample_percent
						from #tmpStats 
						order by [Database_Name]'
		
		END
		ELSE
		BEGIN
		set @sql2 = 'select --*
						Database_Id,
						[Database_Name],
						[Schema_Name],
						[Object_Name],
						[object_id],
						[stats_id],
						[Statistics_Name],
						[last_updated],
						[rows],
						rows_sampled,
						steps,
						unfiltered_rows,
						modification_counter
					from #tmpStats 
					order by [Database_Name]'
		END

		exec (@sql2)
		drop table #tmpStats
		print ''

		--get disabled indexes
		--import in SQLNexus

		set nocount on
		declare @dbname_index sysname, @dbid_index int
		DECLARE dbCursor_Index CURSOR FOR 
		select QUOTENAME(name) name, database_id from sys.databases where state_desc='ONLINE' and database_id > 4 order by name
		OPEN dbCursor_Index

		FETCH NEXT FROM dbCursor_Index  INTO @dbname_index, @dbid_index
		select db_id() 'database_id', db_name() 'database_name', object_name(object_id) 'object_name', object_id,
												name,
												index_id, 
												type, 
												type_desc, 
												is_disabled into #tblDisabledIndex from sys.indexes where is_disabled = 1 and 1=0 


		WHILE @@FETCH_STATUS = 0
		BEGIN
			BEGIN TRY
				declare @sql_index nvarchar (max)
				set @sql_index = 'USE ' + @dbname_index
			
				set @sql_index = @sql_index + '	insert into #tblDisabledIndex	
												select  db_id()  database_id, 
													db_name() database_name, 
													object_name(object_id) object_name, 
													object_id,
													name,
													index_id, 
													type, 
													type_desc, 
													is_disabled
												from sys.indexes where is_disabled = 1'
			
				-- added this check to prevent script from failing on principals with restricted access
				if HAS_PERMS_BY_NAME(@dbname_index, 'DATABASE', 'CONNECT') = 1
					exec (@sql_index)
				else
					PRINT 'Skipped disabled indexes check. Principal ' + SUSER_SNAME() + ' does not have CONNECT permission on database ' + @dbname
				--print @sql
				FETCH NEXT FROM dbCursor_Index  INTO @dbname_index, @dbid_index
			END TRY
			BEGIN CATCH
				PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
				PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
			END CATCH
		END
		close  dbCursor_Index
		deallocate dbCursor_Index
		print ''
		print '--disabled indexes--'
		select * from #tblDisabledIndex order by database_name
		drop table #tblDisabledIndex
		print ''


		print '-- server_times --'
		select CONVERT (varchar(30), getdate(), 126) as server_time, CONVERT (varchar(30), getutcdate(), 126)  utc_time, DATEDIFF(hh, getutcdate(), getdate() ) time_delta_hours

		/*
		this takes too long for large machines
			PRINT '-- High Compile Queries --';
		WITH XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS sp)  
		select   
		stmt.stmt_details.value ('(./sp:QueryPlan/@CompileTime)[1]', 'int') 'CompileTime',
		stmt.stmt_details.value ('(./sp:QueryPlan/@CompileCPU)[1]', 'int') 'CompileCPU',
		SUBSTRING(replace(replace(stmt.stmt_details.value ('@StatementText', 'nvarchar(max)'), char(13), ' '), char(10), ' '), 1, 8000) 'Statement'
		from (   SELECT  query_plan as sqlplan FROM sys.dm_exec_cached_plans AS qs CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle))
		as p       cross apply sqlplan.nodes('//sp:StmtSimple') as stmt (stmt_details)
		order by 1 desc;
		*/
		RAISERROR ('', 0, 1) WITH NOWAIT;
	END TRY
	BEGIN CATCH
		PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
		PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
	END CATCH
END
GO

IF OBJECT_ID ('#sp_perf_stats_snapshot9','P') IS NOT NULL
   DROP PROCEDURE #sp_perf_stats_snapshot9
GO

CREATE PROCEDURE #sp_perf_stats_snapshot9 
AS
BEGIN
	exec #sp_perf_stats_snapshot
END
GO

IF OBJECT_ID ('#sp_perf_stats_snapshot10','P') IS NOT NULL
   DROP PROCEDURE #sp_perf_stats_snapshot10
GO

CREATE PROCEDURE #sp_perf_stats_snapshot10
AS
BEGIN
	BEGIN TRY
		exec #sp_perf_stats_snapshot9

		print 'getting resource governor info'
		print '=========================================='
		print ''
		
		print '-- sys.resource_governor_configuration --'
		declare @sql_major_version INT, @sql_major_build INT, @sql nvarchar (max)

		SELECT @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 4) AS INT)), 
			@sql_major_build = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 2) AS INT)) 
		
		BEGIN
		SET @sql = 'select --* 
						classifier_function_id,
						is_enabled'
		
		IF (@sql_major_version >12)
		BEGIN
			SET @sql = @sql + ',[max_outstanding_io_per_volume]'
		END
		
		SET @sql = @sql + ' from sys.resource_governor_configuration;'
		
		--print @sql
		
		exec (@sql)
		
		END
		print ''
		
		print '-- sys.resource_governor_resource_pools --'
		SET @sql ='select --* 
					pool_id,
					[name],
					min_cpu_percent,
					max_cpu_percent,
					min_memory_percent,
					max_memory_percent'
		IF (@sql_major_version >=11)
		BEGIN
		SET @sql = @sql + ',cap_cpu_percent'
		END
		IF (@sql_major_version >=12)
		BEGIN
		SET @sql = @sql + ',min_iops_per_volume, max_iops_per_volume'
		END

		SET @sql = @sql + ' from sys.resource_governor_resource_pools;'

		--print @sql
		
		exec (@sql)    		 
				
		print ''
		
		print '-- sys.resource_governor_workload_groups --'
		SET @sql ='select --* 
					group_id,
					[name],
					importance,
					request_max_memory_grant_percent,
					request_max_cpu_time_sec,
					request_memory_grant_timeout_sec,
					max_dop,
					group_max_requests,
					pool_id'
		IF (@sql_major_version >=13)
		BEGIN
		SET @sql = @sql + ',external_pool_id'
		END

		SET @sql = @sql + ' from sys.resource_governor_workload_groups'
		
		--print @sql
		
		exec (@sql)    		 

		print ''
		
		print 'Query and plan hash capture '


		--import in SQLNexus	
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
		OPTION (MAX_GRANT_PERCENT = 3, MAXDOP 1)

		print ''


		--import in SQLNexus
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
		OPTION (MAX_GRANT_PERCENT = 3, MAXDOP 1)
		print ''

		--import in SQLNexus
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
		GROUP BY query_hash
		ORDER BY sum(total_elapsed_time) DESC
		) t
		OPTION (MAX_GRANT_PERCENT = 3, MAXDOP 1)
		print ''

		--import in SQLNexus
		print '-- top 10 CPU by query_plan_hash and query_hash --'
		SELECT TOP 10 getdate() as runtime, query_plan_hash, query_hash, 
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
		GROUP BY query_plan_hash, query_hash
		ORDER BY sum(total_worker_time) DESC
		OPTION (MAX_GRANT_PERCENT = 3, MAXDOP 1)
		print ''


		--import in SQLNexus
		print '-- top 10 logical reads by query_plan_hash and query_hash --'
		SELECT TOP 10 getdate() as runtime, query_plan_hash, query_hash, sum(execution_count) as 'execution_count',  
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
		ORDER BY sum(total_logical_reads) DESC
		OPTION (MAX_GRANT_PERCENT = 3, MAXDOP 1)
		print ''

		--import in SQLNexus
		print '-- top 10 elapsed time  by query_plan_hash and query_hash --'
		SELECT TOP 10 getdate() as runtime, query_plan_hash, query_hash, sum(execution_count) as 'execution_count', 
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
		ORDER BY sum(total_elapsed_time) DESC
		OPTION (MAX_GRANT_PERCENT = 3, MAXDOP 1)
	print ''
	END TRY
	BEGIN CATCH
	  PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
	  PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
	END CATCH
END
GO

IF OBJECT_ID ('#sp_perf_stats_snapshot11','P') IS NOT NULL
   DROP PROCEDURE #sp_perf_stats_snapshot11
GO

CREATE PROCEDURE #sp_perf_stats_snapshot11
AS
BEGIN
	exec #sp_perf_stats_snapshot10

END 
GO

IF OBJECT_ID ('#sp_perf_stats_snapshot12','P') IS NOT NULL
   DROP PROCEDURE #sp_perf_stats_snapshot12
GO

CREATE PROCEDURE #sp_perf_stats_snapshot12
as
BEGIN
	exec #sp_perf_stats_snapshot11
END
GO

IF OBJECT_ID ('#sp_perf_stats_snapshot13','P') IS NOT NULL
   DROP PROCEDURE #sp_perf_stats_snapshot13
GO

CREATE PROCEDURE #sp_perf_stats_snapshot13
AS
BEGIN
	BEGIN TRY
		exec #sp_perf_stats_snapshot12

		IF OBJECT_ID ('sys.database_scoped_configurations') IS NOT NULL
		BEGIN

			PRINT '-- sys.database_scoped_configurations --'

			DECLARE @database_id INT
			DECLARE @dbname SYSNAME
			DECLARE @cont INT
			DECLARE @maxcont INT
			DECLARE @sql_major_version INT
			DECLARE @sql_major_build INT
			DECLARE @sql nvarchar (max)
			DECLARE @is_value_default BIT
				
			DECLARE @dbtable TABLE (
			id INT IDENTITY (1,1) PRIMARY KEY,
			database_id INT,
			dbname SYSNAME
			)
			
			SELECT @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)), 4) AS INT)), 
				@sql_major_build = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)), 2) AS INT)) 
			
			INSERT INTO @dbtable
			SELECT database_id, name FROM sys.databases WHERE state_desc='ONLINE' AND name NOT IN ('model','tempdb') ORDER BY name
			
			SET @cont = 1
			SET @maxcont = (SELECT MAX(id) FROM @dbtable)

			--create the schema
			SELECT  @database_id as database_id , @dbname as dbname, configuration_id, name, value, value_for_secondary, @is_value_default AS is_value_default 
			INTO #db_scoped_config
			FROM sys.database_scoped_configurations
			WHERE 1=0
			
			--insert from all databases
			WHILE (@cont<=@maxcont)
			BEGIN
				BEGIN TRY
			
					SELECT @database_id = database_id,
							@dbname = dbname 
					FROM @dbtable
					WHERE id = @cont
					
					SET @sql = 'USE [' + @dbname + ']'
					IF (@sql_major_version > 13)
					BEGIN
						SET @sql = ' INSERT INTO #db_scoped_config SELECT ' + CONVERT(VARCHAR,@database_id) + ',''' + @dbname + ''', configuration_id, name, value, value_for_secondary, is_value_default FROM sys.database_scoped_configurations'
					END
					ELSE
					BEGIN
						SET @sql = ' INSERT INTO #db_scoped_config SELECT ' + CONVERT(VARCHAR,@database_id) + ',''' + @dbname + ''', configuration_id, name, value, value_for_secondary, NULL FROM sys.database_scoped_configurations'
					END
					
					--PRINT @sql
					EXEC (@sql)
					SET @cont = @cont + 1
				END TRY
				BEGIN CATCH
					PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
					PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
				END CATCH
			END
					
			SELECT 
				database_id, 
				CONVERT(VARCHAR(48), dbname) AS dbname, 
				configuration_id, 
				name, 
				CONVERT(VARCHAR(256), value) AS value, 
				CONVERT(VARCHAR(256),value_for_secondary) AS value_for_secondary, 
				is_value_default 
			FROM #db_scoped_config
			PRINT ''
		END
	END TRY
	BEGIN CATCH
		PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
		PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
	END CATCH
END
GO

IF OBJECT_ID ('#sp_perf_stats_snapshot14','P') IS NOT NULL
   DROP PROCEDURE #sp_perf_stats_snapshot14
GO

CREATE PROCEDURE #sp_perf_stats_snapshot14
AS
BEGIN
	exec #sp_perf_stats_snapshot13
END
GO

IF OBJECT_ID ('#sp_perf_stats_snapshot15','P') IS NOT NULL
   DROP PROCEDURE #sp_perf_stats_snapshot15
GO

CREATE PROCEDURE #sp_perf_stats_snapshot15
AS
BEGIN
	BEGIN TRY
		exec #sp_perf_stats_snapshot14
		
		declare @sql_major_version INT
		SELECT @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 4) AS INT))	
		-- Check the MS Version
		IF (@sql_major_version >=15)
		BEGIN
			-- Add identifier
			print '-- sys.index_resumable_operations --'
			SELECT object_id, OBJECT_NAME(object_id) [object_name], index_id, name [index_name],
			sql_text,last_max_dop_used,	partition_number, state, state_desc, start_time, 
			last_pause_time, total_execution_time, percent_complete, page_count 
			FROM sys.index_resumable_operations
			
			PRINT ''
			RAISERROR ('', 0, 1) WITH NOWAIT
		END
	END TRY
	BEGIN CATCH
	  PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
	  PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
	END CATCH
END
GO

IF OBJECT_ID ('#sp_perf_stats_snapshot16','P') IS NOT NULL
   DROP PROCEDURE #sp_perf_stats_snapshot16
GO

CREATE PROCEDURE #sp_perf_stats_snapshot16
AS
BEGIN
	exec #sp_perf_stats_snapshot15
END
GO

/*****************************************************************
*                   main loop   perf statssnapshot               *
******************************************************************/

IF OBJECT_ID ('#sp_Run_PerfStats_Snapshot','P') IS NOT NULL
   DROP PROCEDURE #sp_Run_PerfStats_Snapshot
GO
CREATE PROCEDURE #sp_Run_PerfStats_Snapshot  @IsLite bit=0 
AS 
	BEGIN TRY

		DECLARE @servermajorversion nvarchar(2)
		SET @servermajorversion = REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')
		declare @#sp_perf_stats_snapshot_ver sysname
		set @#sp_perf_stats_snapshot_ver = '#sp_perf_stats_snapshot' + @servermajorversion
		print 'executing procedure ' + @#sp_perf_stats_snapshot_ver
		exec @#sp_perf_stats_snapshot_ver
	END TRY
	BEGIN CATCH
	  PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
	  PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
	END CATCH
GO

exec #sp_Run_PerfStats_Snapshot