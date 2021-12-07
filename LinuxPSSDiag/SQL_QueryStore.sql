
 	declare @dbname sysname
	declare dbCURSOR CURSOR for select name from sys.databases where state_desc='ONLINE' and user_access_desc='MULTI_USER' and is_query_store_on = 1
	declare @sql1 nvarchar(max) = 'select db_id() dbid, db_name() dbname, * from sys.query_store_runtime_stats_interval where start_time > dateadd (dd,-7, getdate())'
	declare @sql2 nvarchar(max) = 'select db_id() dbid, db_name() dbname, * from sys.query_store_runtime_stats where runtime_stats_interval_id in (select runtime_stats_interval_id from sys.query_store_runtime_stats_interval where start_time > dateadd (dd,-7, getdate()))'
	declare @sql3 nvarchar(max) ='select db_id() dbid, db_name() dbname, * from   sys.query_store_query '
	declare @sql4  nvarchar(max) = 'select db_id() dbid, db_name() dbname, query_text_id, statement_sql_handle, is_part_of_encrypted_module, has_restricted_text, substring (REPLACE (REPLACE (query_sql_text,CHAR(13), '' ''), CHAR(10), '' ''), 1, 256)  as  query_sql_text from sys.query_store_query_text'
	declare @sql5 nvarchar(max) = 'select db_id() dbid, db_name() dbname, plan_id, query_id, plan_group_id, engine_version, compatibility_level, query_plan_hash,  is_forced_plan from  sys.query_store_plan'


	declare @sql nvarchar(max)
	open dbCURSOR
	fetch next from dbCursor into @dbname 
	while @@FETCH_STATUS = 0

	begin
	
		RAISERROR ('--sys.query_store_runtime_stats_interval--', 0, 1) WITH NOWAIT
		set @sql = N'use [' + @dbname + '] ' + @sql1
		exec (@sql)
		RAISERROR (' ', 0, 1) WITH NOWAIT

		RAISERROR ('--sys.query_store_runtime_stats--', 0, 1) WITH NOWAIT
		set @sql = N'use [' + @dbname + '] ' + @sql2
		exec (@sql)
		RAISERROR (' ', 0, 1) WITH NOWAIT

		RAISERROR ('--sys.query_store_query--', 0, 1) WITH NOWAIT
		set @sql = N'use [' + @dbname + '] ' + @sql3
		exec (@sql)
		RAISERROR (' ', 0, 1) WITH NOWAIT

		RAISERROR ('--sys.query_store_query_text--', 0, 1) WITH NOWAIT
		set @sql = N'use [' + @dbname + '] ' + @sql4
		exec (@sql)
		RAISERROR (' ', 0, 1) WITH NOWAIT

		RAISERROR ('--sys.query_store_plan--', 0, 1) WITH NOWAIT
		set @sql = N'use [' + @dbname + '] ' + @sql5
		exec (@sql)
		RAISERROR (' ', 0, 1) WITH NOWAIT
		
		
		fetch next from dbCursor into @dbname 
	end

	close dbCURSOR
	deallocate dbCURSOR



--select * from sys.query_store_runtime_stats

--EXEC sp_MSforeachdb 'use [?] select  db_id() ''database_id'', db_name() ''database_name'' ,  plan_id, query_id, query_plan_hash, REPLACE (REPLACE (query_plan ,CHAR(13), '' ''), CHAR(10), '' '')  query_plan from sys.query_store_plan'

 


