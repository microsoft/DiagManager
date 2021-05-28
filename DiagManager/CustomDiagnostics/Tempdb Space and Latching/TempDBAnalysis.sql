GO
WHILE 1=1
BEGIN
select getdate()
DECLARE @runtime datetime
SET @runtime = GETDATE()

PRINT '-- sys.dm_db_file_space_used'
select CONVERT (varchar(30), @runtime, 121) AS runtime, SUM (user_object_reserved_page_count)*8 as usr_obj_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
SUM (version_store_reserved_page_count)*8  as version_store_kb,
SUM (unallocated_extent_page_count)*8 as freespace_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_kb
FROM sys.dm_db_file_space_usage
RAISERROR ('', 0, 1) WITH NOWAIT

PRINT '-- sys.dm_db_session_file_usage'
select top 10 CONVERT (varchar(30), @runtime, 121) AS runtime, * FROM sys.dm_db_session_space_usage  
ORDER BY (user_objects_alloc_page_count + internal_objects_alloc_page_count) DESC
RAISERROR ('', 0, 1) WITH NOWAIT

PRINT '-- sys.dm_db_task_space_usage'
SELECT top 10 CONVERT (varchar(30), @runtime, 121) AS runtime, * FROM sys.dm_db_task_space_usage
ORDER BY (user_objects_alloc_page_count + internal_objects_alloc_page_count) DESC
RAISERROR ('', 0, 1) WITH NOWAIT

PRINT '-- Output from Sysprocesses'
select CONVERT (varchar(30), @runtime, 121) AS runtime, * FROM sys.sysprocesses  
WHERE lastwaittype like 'PAGE%LATCH_%' AND waitresource like '2:%'
RAISERROR ('', 0, 1) WITH NOWAIT

PRINT '-- Output from sys.dm_os_waiting_tasks'
select CONVERT (varchar(30), @runtime, 121) AS runtime, session_id, wait_duration_ms, resource_description
FROM sys.dm_os_waiting_tasks WHERE wait_type like 'PAGE%LATCH_%' AND resource_description like '2:%'
RAISERROR ('', 0, 1) WITH NOWAIT

WAITFOR DELAY '00:00:10'
END
GO 