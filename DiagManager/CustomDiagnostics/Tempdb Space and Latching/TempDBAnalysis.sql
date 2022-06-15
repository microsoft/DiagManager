
SET NOCOUNT ON
USE Tempdb
GO

WHILE 1=1
BEGIN

    PRINT '-- Current time'
    SELECT getdate()
    DECLARE @runtime datetime
    SET @runtime = CONVERT (varchar(30), GETDATE(), 121) 

    PRINT '-- sys.dm_db_file_space_usage --'
    SELECT	@runtime AS runtime, 
		    DB_NAME() AS DbName, 
	    SUM (user_object_reserved_page_count)*8 AS usr_obj_kb,
	    SUM (internal_object_reserved_page_count)*8 AS internal_obj_kb,
	    SUM (version_store_reserved_page_count)*8  AS version_store_kb,
	    SUM (unallocated_extent_page_count)*8 AS freespace_kb,
	    SUM (mixed_extent_page_count)*8 AS mixedextent_kb
    FROM sys.dm_db_file_space_usage 
    PRINT ''


    PRINT '-- Usage By File --'
    SELECT	@runtime AS runtime, 
		    DB_NAME() AS DbName, 
    name AS FileName, 
    size/128.0 AS CurrentSizeMB, 
    size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB
    FROM sys.database_files
    PRINT ''


    PRINT '-- Transaction Counters --'
    SELECT @runtime AS runtime, 
		    DB_NAME() AS DbName, *
    FROM sys.dm_os_performance_counters
    WHERE Object_Name LIKE '%:Transactions%'

    RAISERROR ('', 0, 1) WITH NOWAIT
    PRINT ''

    PRINT '-- sys.dm_db_session_space_usage --'
    SELECT	TOP 10 @runtime AS runtime,
				    DB_NAME() AS DbName, 
				    SS.* ,T.text [Query Text]
    FROM	sys.dm_db_session_space_usage SS
    LEFT JOIN sys.dm_exec_requests CN
	  ON SS.session_id = CN.session_id
    OUTER APPLY sys.dm_exec_sql_text(CN.sql_handle) T
    ORDER BY (user_objects_alloc_page_count + internal_objects_alloc_page_count) DESC
    PRINT ''


    PRINT '-- sys.dm_db_task_space_usage --'
    SELECT TOP 10 @runtime AS runtime,		
		    DB_NAME() AS DbName, 
		    TS.* ,
            T.text [Query Text]
    FROM	sys.dm_db_task_space_usage TS
            INNER JOIN sys.sysprocesses ER 
		    ON ER.ecid= TS.exec_context_id
			    AND ER.spid = TS.session_id
            OUTER APPLY sys.dm_exec_sql_text(ER.sql_handle) T
    ORDER BY (user_objects_alloc_page_count + internal_objects_alloc_page_count) DESC
    PRINT ''


    --CAN WE MERGE THE NEXT TWO STATEMENTS INTO ONE ???
    PRINT '-- version store transactions --'
    SELECT	@runtime AS runtime,a.*,b.kpid,b.blocked,b.lastwaittype,b.waittime
		    , b.waitresource,b.dbid,b.cpu,b.physical_io,b.memusage,b.login_time,b.last_batch,b.open_tran
		    ,b.status,b.hostname,b.program_name,b.cmd,b.loginame,request_id
    FROM	sys.dm_tran_active_snapshot_database_transactions a 
    INNER JOIN sys.sysprocesses b  
	  ON a.session_id = b.spid  
    RAISERROR ('', 0, 1) WITH NOWAIT
    PRINT ''

    PRINT ('-- version store transactions with input buffer --'
    SELECT @runtime AS runtime,b.spid,c.text
    FROM sys.dm_tran_active_snapshot_database_transactions a
    INNER JOIN sys.sysprocesses b
      ON a.session_id = b.spid
    OUTER APPLY sys.dm_exec_sql_text(sql_handle) c
    PRINT ''


    PRINT '-- open transactions --'
       SELECT @runtime AS runtime,
        s_tst.session_id,
		s_es.login_time,
		s_tdt.database_transaction_begin_time,
		s_es.last_request_end_time,
        s_es.login_name AS LoginName,
        DB_NAME (s_tdt.database_id) AS DbName,
        s_tdt.database_transaction_begin_time AS BeginTime,
        s_tdt.database_transaction_log_bytes_used AS LogBytesUsed,
        s_tdt.database_transaction_log_bytes_reserved AS LogReserved,
		con.most_recent_session_id,
		s_es.open_transaction_count,
		s_es.status,
		s_es.host_name,
		s_es.program_name,
		s_es.is_user_process,
		s_es.host_process_id,
		s_es.login_name,
	    con.client_net_address,
		con.net_transport
    FROM sys.dm_tran_database_transactions s_tdt
    JOIN sys.dm_tran_session_transactions s_tst
      ON s_tst.transaction_id = s_tdt.transaction_id
    JOIN sys.dm_exec_sessions AS s_es    
	  ON    s_es.session_id = s_tst.session_id
    LEFT OUTER JOIN sys.dm_exec_requests s_er    
	  ON s_er.session_id = s_tst.session_id
	LEFT OUTER JOIN sys.dm_exec_connections con 
	  ON con.session_id = s_tst.session_id 
    OUTER APPLY sys.dm_exec_sql_text(con.most_recent_sql_handle) T
    ORDER BY BeginTime ASC

    RAISERROR ('', 0, 1) WITH NOWAIT
    PRINT ''

    PRINT '-- Usage by objects --'
    SELECT TOP 10
           @runtime AS runtime,
	       DB_NAME() AS DbName, 
           Cast(ServerProperty('ServerName') AS NVarChar(128)) AS [ServerName],
           DB_ID() AS [DatabaseID],
           DB_Name() AS [DatabaseName],
           [_Objects].[schema_id] AS [SchemaID],
           Schema_Name([_Objects].[schema_id]) AS [SchemaName],
           [_Objects].[object_id] AS [ObjectID],
           RTrim([_Objects].[name]) AS [TableName],
           (~(Cast([_Partitions].[index_id] AS Bit))) AS [IsHeap],       
           SUM([_Partitions].used_page_count) * 8192 UsedPageBytes,
           SUM([_Partitions].reserved_page_count) * 8192 ReservedPageBytes
    FROM   [sys].[objects] AS [_Objects]
    INNER JOIN [sys].[dm_db_partition_stats] AS [_Partitions]
      ON ([_Objects].[object_id] = [_Partitions].[object_id])
    WHERE ([_Partitions].[index_id] IN (0, 1))
    GROUP BY [_Objects].[schema_id],
                  [_Objects].[object_id],
                  [_Objects].[name],
                  [_Partitions].[index_id]
    ORDER BY UsedPageBytes DESC;
    PRINT ''

    PRINT '-- wait-type-Pagelatch-tempdb --'
    SELECT @runtime AS runtime, 
	    session_id,    
	    start_time,                    
	    status,                    
	    command,                        
	    db_name(database_id),
	    blocking_session_id,          
	    wait_type,           
	    wait_time,                      
	    last_wait_type,
	    wait_resource,                  
	    open_transaction_count,
	    cpu_time,        
	    total_elapsed_time,
	    logical_reads                  
    FROM sys.dm_exec_requests
    WHERE wait_type like 'PAGE%LATCH_%' AND wait_resource like '2:%'

    PRINT '-- Output from sys.dm_os_waiting_tasks --'
    SELECT @runtime AS runtime, 
        session_id, 
        wait_duration_ms, 
        resource_description
    FROM sys.dm_os_waiting_tasks 
    WHERE wait_type LIKE 'PAGE%LATCH_%' 
      AND resource_description LIKE '2:%'

    RAISERROR ('', 0, 1) WITH NOWAIT
    PRINT ''


    WAITFOR DELAY '00:01:00'
END
GO 