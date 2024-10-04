-------------------------------memory collectors ------------------------------------------------------------------------------------------------

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
perf mem stats snapshot

********************************************************************/
IF OBJECT_ID ('sp_mem_stats_grants_mem_script','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats_grants_mem_script
GO
--2017-01-10 changed query text be at statement level
CREATE PROCEDURE sp_mem_stats_grants_mem_script @runtime datetime , @lastruntime datetime =null
AS
BEGIN TRY

  print '-- query execution memory mem_script--'
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
      , ltrim(rtrim(replace(replace (substring (SUBSTRING(q.text,r.statement_start_offset/2 +1,  (CASE WHEN r.statement_end_offset = -1  THEN LEN(CONVERT(nvarchar(max), q.text)) * 2   ELSE r.statement_end_offset end -   r.statement_start_offset   )/2 ) , 1, 1000), char(10), ' '), char(13), ' '))) [text]
          --, ltrim(rtrim(replace(replace (substring (q.text, 1, 1000), char(10), ' '), char(13), ' '))) [text]
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
      , object_name (q.objectid, q.dbid) 'Object_Name'
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
  OPTION (max_grant_percent = 3, MAXDOP 1)

  RAISERROR ('', 0, 1) WITH NOWAIT
END TRY
BEGIN CATCH
	  PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
	  PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
END CATCH
GO

IF OBJECT_ID ('sp_mem_stats_proccache','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats_proccache
GO

CREATE PROCEDURE sp_mem_stats_proccache @runtime datetime , @lastruntime datetime=null
AS

-- This procedure is designed to be run periodically to track the size of the plan cache over time.

BEGIN TRY

  PRINT '-- proccache_summary'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, 
-- We have to cast usecounts as bigint to avoid arithmetic overflow in large TB memory sized servers.

         SUM (cast (size_in_bytes as bigint)) AS total_size_in_bytes, COUNT(*) AS plan_count, AVG (cast(usecounts as bigint)) AS avg_usecounts
  FROM sys.dm_exec_cached_plans
  RAISERROR ('', 0, 1) WITH NOWAIT


  -- Check for plans that are "polluting" the proc cache with trivial variations 
  -- (typically due to a lack of parameterization)
  PRINT '-- proccache_pollution';
  WITH cached_plans (cacheobjtype, objtype, usecounts, size_in_bytes, dbid, objectid, short_qry_text) AS 
  (
    SELECT p.cacheobjtype, p.objtype, p.usecounts, size_in_bytes, s.dbid, s.objectid, 
      CONVERT (nvarchar(100), REPLACE (REPLACE (
        CASE 
          -- Special cases: handle NULL s.[text] and 'SET NOEXEC'
          WHEN s.[text] IS NULL THEN NULL 
          WHEN CHARINDEX ('noexec', SUBSTRING (s.[text], 1, 200)) > 0 THEN SUBSTRING (s.[text], 1, 40)
          -- CASE #1: sp_executesql (query text passed in as 1st parameter) 
          WHEN (CHARINDEX ('sp_executesql', SUBSTRING (s.[text], 1, 200)) > 0) 
          THEN SUBSTRING (s.[text], CHARINDEX ('exec', SUBSTRING (s.[text], 1, 200)), 60) 
          -- CASE #3: any other stored proc -- strip off any parameters
          WHEN CHARINDEX ('exec ', SUBSTRING (s.[text], 1, 200)) > 0 
          THEN SUBSTRING (s.[text], CHARINDEX ('exec', SUBSTRING (s.[text], 1, 4000)), 
            CHARINDEX (' ', SUBSTRING (SUBSTRING (s.[text], 1, 200) + '   ', CHARINDEX ('exec', SUBSTRING (s.[text], 1, 500)), 200), 9) )
          -- CASE #4: stored proc that starts with common prefix 'sp%' instead of 'exec'
          WHEN SUBSTRING (s.[text], 1, 2) IN ('sp', 'xp', 'usp')
          THEN SUBSTRING (s.[text], 1, CHARINDEX (' ', SUBSTRING (s.[text], 1, 200) + ' '))
          -- CASE #5: ad hoc UPD/INS/DEL query (on average, updates/inserts/deletes usually 
          -- need a shorter substring to avoid hitting parameters)
          WHEN SUBSTRING (s.[text], 1, 30) LIKE '%UPDATE %' OR SUBSTRING (s.[text], 1, 30) LIKE '%INSERT %' 
            OR SUBSTRING (s.[text], 1, 30) LIKE '%DELETE %' 
          THEN SUBSTRING (s.[text], 1, 30)
          -- CASE #6: other ad hoc query
          ELSE SUBSTRING (s.[text], 1, 45)
        END
      , CHAR (10), ' '), CHAR (13), ' ')) AS short_qry_text 
    FROM sys.dm_exec_cached_plans p
    CROSS APPLY sys.dm_exec_sql_text (p.plan_handle) s
  ) 
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, 
    COUNT(*) AS plan_count, SUM (cast (size_in_bytes as bigint)) AS total_size_in_bytes,
    cacheobjtype, objtype, usecounts, dbid, objectid, short_qry_text 
  FROM cached_plans
  GROUP BY cacheobjtype, objtype, usecounts, dbid, objectid, short_qry_text
  HAVING COUNT(*) > 100
  ORDER BY COUNT(*) DESC
  RAISERROR ('', 0, 1) WITH NOWAIT
END TRY
BEGIN CATCH
	  PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
	  PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
END CATCH
GO

IF OBJECT_ID ('sp_mem_stats_general','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats_general
GO

CREATE PROCEDURE sp_mem_stats_general @runtime datetime , @lastruntime datetime=null
AS


-- get the current major build of SQL Server
DECLARE @sql_major_version INT
SELECT @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 4) AS INT))

BEGIN TRY

  IF OBJECT_ID('tempdb..#db_inmemory') IS NOT NULL
  DROP TABLE #db_inmemory;
  
  IF OBJECT_ID('tempdb..#tmp_dm_db_xtp_index_stats ') IS NOT NULL
  DROP TABLE #tmp_dm_db_xtp_index_stats ;
  
  IF OBJECT_ID('tempdb..#tmp_dm_db_xtp_hash_index_stats ') IS NOT NULL
  DROP TABLE #tmp_dm_db_xtp_hash_index_stats ;
  
  IF OBJECT_ID('tempdb..#tmp_dm_db_xtp_table_memory_stats') IS NOT NULL
  DROP TABLE #tmp_dm_db_xtp_table_memory_stats;
  
  IF OBJECT_ID('tempdb..#tmp_dm_db_xtp_memory_consumers') IS NOT NULL
  DROP TABLE #tmp_dm_db_xtp_memory_consumers;

  PRINT '-- dm_os_memory_cache_counters'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM sys.dm_os_memory_cache_counters
  RAISERROR ('', 0, 1) WITH NOWAIT


  PRINT '-- dm_os_sys_memory'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM sys.dm_os_sys_memory
  RAISERROR ('', 0, 1) WITH NOWAIT

  PRINT '-- dm_os_process_memory'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM sys.dm_os_process_memory
  RAISERROR ('', 0, 1) WITH NOWAIT


  PRINT '-- dm_os_memory_clerks'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM sys.dm_os_memory_clerks
  RAISERROR ('', 0, 1) WITH NOWAIT


  PRINT '-- dm_os_memory_cache_clock_hands'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM sys.dm_os_memory_cache_clock_hands
  RAISERROR ('', 0, 1) WITH NOWAIT


  PRINT '-- dm_os_memory_cache_hash_tables'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM sys.dm_os_memory_cache_hash_tables
  RAISERROR ('', 0, 1) WITH NOWAIT


  PRINT '-- dm_os_memory_pools'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM sys.dm_os_memory_pools
  RAISERROR ('', 0, 1) WITH NOWAIT


  PRINT '-- sys.dm_os_loaded_modules (non-Microsoft)'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM sys.dm_os_loaded_modules 
  WHERE (company NOT LIKE '%Microsoft%' OR company IS NULL)
    AND UPPER (name) NOT LIKE '%_NSTAP_.DLL' -- instapi.dll (MS dll), with "i"'s wildcarded for Turkish systems
    AND UPPER (name) NOT LIKE '%\ODBC32.DLL' -- ODBC32.dll (MS dll)
  RAISERROR ('', 0, 1) WITH NOWAIT


  PRINT '-- sys.dm_os_sys_info'
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * 
  FROM sys.dm_os_sys_info
  RAISERROR ('', 0, 1) WITH NOWAIT



  PRINT '-- sys.dm_os_memory_objects (total memory by type, >1MB)'

DECLARE @sqlmemobj NVARCHAR(2048)
IF  @sql_major_version < 11  --prior to 2012
BEGIN
	SET @sqlmemobj = 
	'SELECT CONVERT (varchar(30), @runtime, 121) as runtime, ' + 
	  'SUM (CONVERT(bigint, (pages_allocated_count * page_size_in_bytes))) AS ''total_bytes_used'', type ' + 
	'FROM sys.dm_os_memory_objects ' + 
	'GROUP BY type  ' + 
	'HAVING SUM (CONVERT(bigint,pages_allocated_count) * page_size_in_bytes) >= (1024*1024)  ' + 
	'ORDER BY SUM (CONVERT(bigint,pages_allocated_count) * page_size_in_bytes) DESC '
END
ELSE
BEGIN
	SET @sqlmemobj =
	'SELECT CONVERT (varchar(30), @runtime, 121) as runtime,  ' + 
	  'SUM (CONVERT(bigint, pages_in_bytes)) AS ''total_bytes_used'', type  ' + 
	'FROM sys.dm_os_memory_objects ' + 
	'GROUP BY type  ' + 
	'HAVING SUM (CONVERT(bigint,pages_in_bytes)) >= (1024*1024) ' + 
	'ORDER BY SUM (CONVERT(bigint,pages_in_bytes)) DESC '
END	

EXEC SP_EXECUTESQL @sqlmemobj, N'@runtime datetime', @runtime
RAISERROR ('', 0, 1) WITH NOWAIT

-- -- Check for windows memory notifications
PRINT '-- memory_workingset_trimming'
SELECT 
CONVERT (varchar(30), @runtime, 121) as runtime,
DATEADD (ms, a.[Record Time] - sys.ms_ticks, @runtime) AS Notification_time, 	
	a.* ,
sys.ms_ticks AS [Current Time]
	FROM 
	(SELECT x.value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') AS [Notification_type], 
	x.value('(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint') AS [MemoryUtilization %], 
	x.value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') AS [TotalPhysicalMemory_KB], 
	x.value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [AvailablePhysicalMemory_KB], 
	x.value('(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint') AS [TotalPageFile_KB], 
	x.value('(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint') AS [AvailablePageFile_KB], 
	x.value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') AS [TotalVirtualAddressSpace_KB], 
	x.value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [AvailableVirtualAddressSpace_KB], 
	x.value('(//Record/MemoryNode/@id)[1]', 'int') AS [Node Id], 
	x.value('(//Record/MemoryNode/ReservedMemory)[1]', 'bigint') AS [SQL_ReservedMemory_KB], 
	x.value('(//Record/MemoryNode/CommittedMemory)[1]', 'bigint') AS [SQL_CommittedMemory_KB], 
	x.value('(//Record/@id)[1]', 'bigint') AS [Record Id], 
	x.value('(//Record/@type)[1]', 'varchar(30)') AS [Type], 
	x.value('(//Record/ResourceMonitor/IndicatorsProcess)[1]', 'bigint') AS [IndicatorsProcess], 
	x.value('(//Record/ResourceMonitor/IndicatorsSystem)[1]', 'bigint') AS [IndicatorsSystem], 
	x.value('(//Record/ResourceMonitor/IndicatorsPool)[1]', 'bigint') AS [IndicatorsPool], 
	x.value('(//Record/@time)[1]', 'bigint') AS [Record Time]
	FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers 
	WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR') AS R(x)) a 
CROSS JOIN sys.dm_os_sys_info sys
WHERE DATEADD (ms, a.[Record Time] - sys.ms_ticks, @runtime) BETWEEN @lastruntime AND @runtime
ORDER BY DATEADD (ms, a.[Record Time] - sys.ms_ticks, @runtime)
RAISERROR ('', 0, 1) WITH NOWAIT

PRINT '-- sys.dm_os_ring_buffers (RING_BUFFER_RESOURCE_MONITOR and RING_BUFFER_MEMORY_BROKER)'
SELECT CONVERT (varchar(30), @runtime, 121) as runtime, 
  DATEADD (ms, ring.[timestamp] - sys.ms_ticks, GETDATE()) AS record_time, 
  ring.[timestamp] AS record_timestamp, sys.ms_ticks AS cur_timestamp, ring.* 
FROM sys.dm_os_ring_buffers ring
CROSS JOIN sys.dm_os_sys_info sys
WHERE ring.ring_buffer_type IN ( 'RING_BUFFER_RESOURCE_MONITOR' , 'RING_BUFFER_MEMORY_BROKER' )
  AND DATEADD (ms, ring.timestamp - sys.ms_ticks, GETDATE()) BETWEEN @lastruntime AND GETDATE()
RAISERROR ('', 0, 1) WITH NOWAIT

PRINT '-- sys.dm_os_memory_brokers --'
SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * 
FROM sys.dm_os_memory_brokers 
RAISERROR ('', 0, 1) WITH NOWAIT


--In-Memory OLTP related data

DECLARE @database_id INT
DECLARE @dbname SYSNAME
DECLARE @count INT
DECLARE @maxcount INT
DECLARE @sql NVARCHAR(MAX)

DECLARE @dbtable TABLE (id INT IDENTITY (1,1) PRIMARY KEY,
			                  database_id INT,
			                  dbname SYSNAME
			                 )

IF (@sql_major_version > 11) 
BEGIN

  --database level in-memory dmvs

  SELECT IDENTITY(INT,1,1) AS id, 
         @database_id as database_id , 
         @dbname as dbname 
  INTO #db_inmemory
  FROM sys.databases
  WHERE 1=0
    
  INSERT INTO @dbtable
  SELECT database_id, name FROM sys.databases WHERE state_desc='ONLINE' 
  
  SET @count = 1
  SET @maxcount = (SELECT MAX(id) FROM @dbtable)
  
  WHILE (@count<=@maxcount)
  BEGIN
    SELECT @database_id = database_id,
    	     @dbname = dbname 
    FROM @dbtable
    WHERE id = @count
  
    SET @sql = N'USE [' + @dbname + '];
  	           IF EXISTS(SELECT type_desc FROM sys.data_spaces WHERE type_desc = ''MEMORY_OPTIMIZED_DATA_FILEGROUP'')
  	           BEGIN
  			         INSERT INTO #db_inmemory VALUES (' + CONVERT(NVARCHAR(50),@database_id) + ',''' + @dbname +''');
  			       END'
  --print @sql
    EXEC (@sql)
    SET @count = @count + 1

  END

  SET @count = 1
  SET @maxcount = (SELECT MAX(id) FROM #db_inmemory)

  PRINT '-- sys.dm_db_xtp_index_stats --'

  CREATE TABLE #tmp_dm_db_xtp_index_stats (
    [dbname] SYSNAME NULL,
    [object_id] BIGINT NULL,
    [xtp_object_id]BIGINT NULL,
    [index_name] SYSNAME NULL,
    [scans_started]BIGINT NULL,
    [scans_retries]BIGINT NULL,
    [rows_returned]BIGINT NULL,
    [rows_touched]BIGINT NULL,
    [rows_expiring]BIGINT NULL,
    [rows_expired]BIGINT NULL,
    [rows_expired_removed]BIGINT NULL,
    [phantom_scans_started]BIGINT NULL,
    [phantom_scans_retries]BIGINT NULL,
    [phantom_rows_touched]BIGINT NULL,
    [phantom_expiring_rows_encountered]BIGINT NULL,
    [phantom_expired_removed_rows_encountered]BIGINT NULL,
    [phantom_expired_rows_removed]BIGINT NULL,
    [object_address]VARBINARY(8) NULL
  )

  WHILE (@count<=@maxcount)
  BEGIN
  
    SELECT @database_id = database_id,
  	       @dbname = dbname 
    FROM #db_inmemory
    WHERE id = @count
  
    IF (@sql_major_version >=13 )
    BEGIN
      SET @sql = N'USE [' + @dbname + '];
     	 		         INSERT INTO #tmp_dm_db_xtp_index_stats
     				       SELECT '''+@dbname+''',
  						            [object_id],					    
                          [xtp_object_id],
                          [index_id],
                          [scans_started],
                          [scans_retries],
                          [rows_returned],
                          [rows_touched],
                          [rows_expiring],
                          [rows_expired],
                          [rows_expired_removed],
                          [phantom_scans_started],
                          [phantom_scans_retries],
                          [phantom_rows_touched],
                          [phantom_expiring_rows_encountered],
                          [phantom_expired_removed_rows_encountered],
                          [phantom_expired_rows_removed],
                          [object_address]
     				       FROM sys.dm_db_xtp_index_stats ids;'
    END
    ELSE
    BEGIN
      SET @sql = N'USE [' + @dbname + '];
     	 		         INSERT INTO #tmp_dm_db_xtp_index_stats
     				       SELECT '''+@dbname+''',
  						            [object_id],
                         	NULL,--[xtp_object_id],
                         	[index_id],
                         	[scans_started],
                         	[scans_retries],
                         	[rows_returned],
                         	[rows_touched],
                         	[rows_expiring],
                         	[rows_expired],
                         	[rows_expired_removed],
                         	[phantom_scans_started],
                         	[phantom_scans_retries],
                         	[phantom_rows_touched],
                         	[phantom_expiring_rows_encountered],
                         	[phantom_expired_removed_rows_encountered],
                         	[phantom_expired_rows_removed],
                         	[object_address]
     					     FROM sys.dm_db_xtp_index_stats AS ids;'  						       
    END
   
     --print @sql
     EXEC (@sql)
     SET @count = @count + 1
  END
  
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM #tmp_dm_db_xtp_index_stats 
  RAISERROR ('', 0, 1) WITH NOWAIT

  PRINT '-- sys.dm_db_xtp_hash_index_stats --'
 
  SET @count = 1
  SET @maxcount = (SELECT MAX(id) FROM #db_inmemory)
 
  CREATE TABLE #tmp_dm_db_xtp_hash_index_stats(
   dbname SYSNAME NULL,
   objname SYSNAME NULL,
   indexname SYSNAME NULL,
   total_bucket_count BIGINT NULL,
   empty_bucket_count BIGINT NULL,
   empty_bucket_percent FLOAT NULL,
   avg_chain_length BIGINT NULL,
   max_chain_length BIGINT NULL
  )
 
  WHILE (@count<=@maxcount)
  BEGIN
  
     SELECT @database_id = database_id,
  	      @dbname = dbname 
     FROM #db_inmemory
     WHERE id = @count
  
    SET @sql = N'USE [' + @dbname + '];
  	           INSERT INTO #tmp_dm_db_xtp_hash_index_stats
  			       SELECT '''+@dbname+''',
                      OBJECT_NAME(hs.object_id),  
                      i.name,  
                      hs.total_bucket_count, 
                      hs.empty_bucket_count, 
                      FLOOR((CAST(empty_bucket_count as float)/total_bucket_count) * 100), 
                      hs.avg_chain_length,  
                      hs.max_chain_length 
               FROM sys.dm_db_xtp_hash_index_stats AS hs  
                 INNER JOIN sys.indexes AS i  
                   ON hs.object_id=i.object_id AND hs.index_id=i.index_id'
      
    
    --print @sql
    EXEC (@sql)
    SET @count = @count + 1
  END
 
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime,* FROM #tmp_dm_db_xtp_hash_index_stats
  RAISERROR ('', 0, 1) WITH NOWAIT
  
  PRINT '-- sys.dm_db_xtp_table_memory_stats --'
  
  SET @count = 1
  SET @maxcount = (SELECT MAX(id) FROM #db_inmemory)
  
  CREATE TABLE #tmp_dm_db_xtp_table_memory_stats(
    [dbname] SYSNAME NULL,
    [object_name] SYSNAME NULL,
    [object_id] BIGINT NULL,
    [memory_allocated_for_table_kb] BIGINT NULL,
    [memory_used_by_table_kb] BIGINT NULL,
    [memory_allocated_for_indexes_kb] BIGINT NULL,
    [memory_used_by_indexes_kb] BIGINT NULL
  )
  
  
  WHILE (@count<=@maxcount)
  BEGIN
  
     SELECT @database_id = database_id,
  	      @dbname = dbname 
     FROM #db_inmemory
     WHERE id = @count
  
     SET @sql = N'USE [' + @dbname + '];
  	            INSERT INTO #tmp_dm_db_xtp_table_memory_stats
                  SELECT '''+@dbname+''',
                         OBJECT_NAME(object_id),
                         [object_id],
                         [memory_allocated_for_table_kb],
                         [memory_used_by_table_kb],
                         [memory_allocated_for_indexes_kb],
                         [memory_used_by_indexes_kb]
                  FROM sys.dm_db_xtp_table_memory_stats
                  OPTION (FORCE ORDER);'
  
    --print @sql
    EXEC (@sql)
    SET @count = @count + 1
  
  END
  
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime,* from #tmp_dm_db_xtp_table_memory_stats
  RAISERROR ('', 0, 1) WITH NOWAIT
  
  PRINT '-- sys.dm_db_xtp_memory_consumers --'
  
  SET @count = 1
  SET @maxcount = (SELECT MAX(id) FROM #db_inmemory)
  
  CREATE TABLE #tmp_dm_db_xtp_memory_consumers (
  	[dbname] SYSNAME NULL,
  	[object_name] SYSNAME NULL,
  	[memory_consumer_id] BIGINT NULL, 
  	[memory_consumer_type] INT NULL,
  	[memory_consumer_type_desc]NVARCHAR(64) NULL,
  	[memory_consumer_desc]NVARCHAR(64) NULL,
  	[object_id] BIGINT NULL,
  	[xtp_object_id] BIGINT NULL,
  	[index_id] INT NULL,
  	[allocated_bytes] BIGINT NULL,
  	[used_bytes] BIGINT NULL,
  	[allocation_count] INT NULL,
  	[partition_count] INT NULL,
  	[sizeclass_count] INT NULL,
  	[min_sizeclass] INT NULL,
  	[max_sizeclass]INT NULL,
  	[memory_consumer_address] VARBINARY(8) NULL
  	)
  
  
  
  WHILE (@count<=@maxcount)
  BEGIN
  
    SELECT @database_id = database_id,
        @dbname = dbname 
    FROM #db_inmemory
    WHERE id = @count
  
    IF (@sql_major_version >=13 )
    BEGIN
      SET @sql = N'USE [' + @dbname + ']; 
                   INSERT INTO #tmp_dm_db_xtp_memory_consumers
  	  		         SELECT '''+@dbname+''',
  	  			       	      CONVERT(char(20), OBJECT_NAME(object_id)) AS Name, 
  	  		                [memory_consumer_id],
  	                      [memory_consumer_type],
  	                      [memory_consumer_type_desc],
  	                      [memory_consumer_desc],
  	                      [object_id],
  	                      [xtp_object_id],
  	                      [index_id],
  	                      [allocated_bytes],
  	                      [used_bytes],
  	                      [allocation_count],
  	                      [partition_count],
  	                      [sizeclass_count],
  	                      [min_sizeclass],
  	                      [max_sizeclass],
  	                      [memory_consumer_address]
                   FROM sys.dm_db_xtp_memory_consumers;'
    END
    ELSE
    BEGIN
    
      SET @sql = N'USE [' + @dbname + ']; 
                   INSERT INTO #tmp_dm_db_xtp_memory_consumers
  	  		         SELECT '''+@dbname+''',
  	  			       	      CONVERT(char(20), OBJECT_NAME(object_id)) AS Name, 
  	  		                [memory_consumer_id],
  	                      [memory_consumer_type],
  	                      [memory_consumer_type_desc],
  	                      [memory_consumer_desc],
  	                      [object_id],
  	                      NULL,--[xtp_object_id],
  	                      [index_id],
  	                      [allocated_bytes],
  	                      [used_bytes],
  	                      [allocation_count],
  	                      [partition_count],
  	                      [sizeclass_count],
  	                      [min_sizeclass],
  	                      [max_sizeclass],
  	                      [memory_consumer_address]
                   FROM sys.dm_db_xtp_memory_consumers;'
      

    END
  
    --print @sql
    EXEC (@sql)
    SET @count = @count + 1
  
  END
  
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM #tmp_dm_db_xtp_memory_consumers
  RAISERROR ('', 0, 1) WITH NOWAIT  
  
  PRINT '-- sys.dm_db_xtp_object_stats --'

  SET @count = 1
  SET @maxcount = (SELECT MAX(id) FROM #db_inmemory)
	  
	CREATE table #tmp_dm_db_xtp_object_stats(
      [dbname] SYSNAME NULL,
      [object_id]BIGINT NULL,
      [xtp_object_id]BIGINT NULL,
      [row_insert_attempts]BIGINT NULL,
      [row_update_attempts]BIGINT NULL,
      [row_delete_attempts]BIGINT NULL,
      [write_conflicts]BIGINT NULL,
      [unique_constraint_violations]BIGINT NULL,
      [object_address] VARBINARY(8)
  )

	WHILE (@count<=@maxcount)
  BEGIN
  
    SELECT @database_id = database_id,
  	       @dbname = dbname 
    FROM #db_inmemory
    WHERE id = @count
  
    IF (@sql_major_version >=13 )
    BEGIN
      SET @sql = N'USE [' + @dbname + '];
     	 		         INSERT INTO #tmp_dm_db_xtp_object_stats
     			         SELECT '''+@dbname+''',
  				                [object_id],
                          [xtp_object_id],
                          [row_insert_attempts],
                          [row_update_attempts],
                          [row_delete_attempts],
                          [write_conflicts],
                          [unique_constraint_violations],
                          [object_address]
                    FROM sys.dm_db_xtp_object_stats;'
                          
    END
    ELSE
    BEGIN
      SET @sql = N'USE [' + @dbname + '];
     	 		         INSERT INTO #tmp_dm_db_xtp_object_stats
     			         SELECT '''+@dbname+''',
  				                [object_id],
                          NULL, --[xtp_object_id],
                          [row_insert_attempts],
                          [row_update_attempts],
                          [row_delete_attempts],
                          [write_conflicts],
                          [unique_constraint_violations],
                          [object_address]
                   FROM sys.dm_db_xtp_object_stats;'
    END
   
     --print @sql
     EXEC (@sql)
     SET @count = @count + 1
     
  END

	SELECT CONVERT (varchar(30), @runtime, 121) as runtime, * FROM #tmp_dm_db_xtp_object_stats 
  RAISERROR ('', 0, 1) WITH NOWAIT	  
    
  --instance level in-memory dmvs
  PRINT '-- sys.dm_xtp_system_memory_consumers --'
  
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime,
  	   [memory_consumer_id],
  	   [memory_consumer_type],
  	   [memory_consumer_type_desc],
  	   [memory_consumer_desc],
  	   [lookaside_id],
  	   [allocated_bytes],
  	   [used_bytes],
  	   [allocation_count],
  	   [partition_count],
  	   [sizeclass_count],
  	   [min_sizeclass],
  	   [max_sizeclass],
  	   [memory_consumer_address]
  FROM sys.dm_xtp_system_memory_consumers
  WHERE allocated_bytes > 0
  RAISERROR ('', 0, 1) WITH NOWAIT
  
  PRINT '-- sys.dm_xtp_system_memory_consumers_summary --'
  
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime,
         SUM(allocated_bytes) / (1024 * 1024) AS total_allocated_MB,
         SUM(used_bytes) / (1024 * 1024) AS total_used_MB
  FROM sys.dm_xtp_system_memory_consumers
  RAISERROR ('', 0, 1) WITH NOWAIT
  
  PRINT '-- sys.dm_xtp_gc_stats --'
  
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime,
  	[rows_examined],
  	[rows_no_sweep_needed],
  	[rows_first_in_bucket],
  	[rows_first_in_bucket_removed],
  	[rows_marked_for_unlink],
  	[parallel_assist_count],
  	[idle_worker_count],
  	[sweep_scans_started],
  	[sweep_scan_retries],
  	[sweep_rows_touched],
  	[sweep_rows_expiring],
  	[sweep_rows_expired],
  	[sweep_rows_expired_removed]
  FROM sys.dm_xtp_gc_stats
  RAISERROR ('', 0, 1) WITH NOWAIT
  
  
  PRINT '-- sys.dm_xtp_gc_queue_stats --'
  
  SELECT CONVERT (varchar(30), @runtime, 121) as runtime,
  	   [queue_id],
  	   [total_enqueues],
  	   [total_dequeues],
  	   [current_queue_depth],
  	   [maximum_queue_depth],
  	   [last_service_ticks]
  FROM sys.dm_xtp_gc_queue_stats
  ORDER BY current_queue_depth DESC
  RAISERROR ('', 0, 1) WITH NOWAIT
 
END
ELSE
BEGIN
  PRINT 'No XTP supported in this version of SQL Server'
  RAISERROR ('', 0, 1) WITH NOWAIT
END
END TRY
BEGIN CATCH
	  PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
	  PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
END CATCH
go


IF OBJECT_ID ('sp_mem_stats9','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats9
GO
go
CREATE PROCEDURE sp_mem_stats9  @runtime datetime , @lastruntime datetime =null
AS 
begin
	exec sp_mem_stats_grants_mem_script @runtime, @lastruntime
	exec sp_mem_stats_proccache @runtime, @lastruntime
	exec sp_mem_stats_general @runtime, @lastruntime
end
go

IF OBJECT_ID ('sp_mem_stats10','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats10
GO
go
CREATE PROCEDURE sp_mem_stats10  @runtime datetime , @lastruntime datetime =null
AS 
begin
	exec sp_mem_stats9  @runtime, @lastruntime
end
go


IF OBJECT_ID ('sp_mem_stats11','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats11
GO
go
CREATE PROCEDURE sp_mem_stats11  @runtime datetime , @lastruntime datetime =null
AS 
begin
	exec sp_mem_stats10  @runtime, @lastruntime
end
go

IF OBJECT_ID ('sp_mem_stats12','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats12
GO
go
CREATE PROCEDURE sp_mem_stats12  @runtime datetime , @lastruntime datetime =null
AS 
begin
	exec sp_mem_stats11  @runtime, @lastruntime
end
go

IF OBJECT_ID ('sp_mem_stats13','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats13
GO
go
CREATE PROCEDURE sp_mem_stats13  @runtime datetime , @lastruntime datetime =null
AS 
begin
	exec sp_mem_stats12  @runtime, @lastruntime
end
go

IF OBJECT_ID ('sp_mem_stats14','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats14
GO
go
CREATE PROCEDURE sp_mem_stats14  @runtime datetime , @lastruntime datetime =null
AS 
begin
	exec sp_mem_stats13  @runtime, @lastruntime
end
go

IF OBJECT_ID ('sp_mem_stats15','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats15
GO
go
CREATE PROCEDURE sp_mem_stats15  @runtime datetime , @lastruntime datetime =null
AS 
begin
	exec sp_mem_stats14  @runtime, @lastruntime
end
go	       

IF OBJECT_ID ('sp_mem_stats16','P') IS NOT NULL
   DROP PROCEDURE sp_mem_stats16
GO
go
CREATE PROCEDURE sp_mem_stats16  @runtime datetime , @lastruntime datetime =null
AS 
begin
	exec sp_mem_stats15  @runtime, @lastruntime
end
go	       



IF OBJECT_ID ('sp_Run_MemStats','P') IS NOT NULL
   DROP PROCEDURE sp_Run_MemStats
GO
create procedure sp_Run_MemStats @WaitForDelayString nvarchar(10)
as
DECLARE @runtime datetime
DECLARE @lastruntime datetime
SET @lastruntime = '19000101'

DECLARE @servermajorversion nvarchar(2)
SET @servermajorversion = REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')
declare @sp_mem_stats_ver sysname
set @sp_mem_stats_ver = 'sp_mem_stats' + @servermajorversion

print 'running memory collector ' + @sp_mem_stats_ver
WHILE (1=1)
BEGIN
  BEGIN TRY
    SET @runtime = GETDATE()
    PRINT ''
    PRINT 'Start time: ' + CONVERT (varchar (50), GETDATE(), 121)
    PRINT ''

    exec @sp_mem_stats_ver @runtime, @lastruntime

      -- Save current runtime -- we'll use it to display only new ring buffer records on the next snapshot
    SET @lastruntime = DATEADD (s, -15, @runtime) -- allow for up to a 15 second snapshot runtime without missing records
    -- flush the buffer
    RAISERROR ('', 0,1) WITH NOWAIT
    WAITFOR DELAY @WaitForDelayString
  END TRY
  BEGIN CATCH
				PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
				PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
  END CATCH
END
GO

exec sp_Run_MemStats '0:2:0'