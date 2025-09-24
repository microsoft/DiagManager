use tempdb
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

IF OBJECT_ID ('#sp_perf_virtual_file_stats','P') IS NOT NULL
DROP PROCEDURE #sp_perf_virtual_file_stats
GO
CREATE PROCEDURE #sp_perf_virtual_file_stats @appname sysname='pssdiag', @runtime DATETIME, @runtime_utc DATETIME
AS
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        PRINT ''
        PRINT '-- file_io_stats --'
        SELECT  CONVERT (VARCHAR(30), @runtime, 126) AS runtime, CONVERT (VARCHAR(30), @runtime_utc, 126) AS runtime_utc,
                CONVERT(VARCHAR(40), DB_NAME(vfs.database_id)) AS DATABASE_NAME, physical_name AS Physical_Name,
                size_on_disk_bytes / 1024 / 1024.0 AS File_Size_MB ,
                CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS Average_Read_Latency,
                CAST(io_stall_write_ms/(1.0 + num_of_writes) AS NUMERIC(10,1)) AS Average_Write_Latency,
                num_of_bytes_read / NULLIF(num_of_reads, 0) AS Average_Bytes_Read,
                num_of_bytes_written / NULLIF(num_of_writes, 0) AS Average_Bytes_Write
        FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
        JOIN sys.master_files AS mf 
            ON vfs.database_id = mf.database_id AND vfs.file_id = mf.file_id
        WHERE (CAST(io_stall_write_ms/(1.0 + num_of_writes) AS NUMERIC(10,1))> 15
                OR (CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1))> 15))
        ORDER BY Average_Read_Latency DESC
        OPTION (max_grant_percent = 3, MAXDOP 1)

        --flush results to client
        RAISERROR (' ', 0, 1) WITH NOWAIT
    END TRY
    BEGIN CATCH
    PRINT 'Exception occured in: `"' + OBJECT_NAME(@@PROCID)  + '`"'     
    PRINT 'Msg ' + isnull(cast(Error_Number() AS NVARCHAR(50)), '') + ', Level ' + isnull(cast(Error_Severity() AS NVARCHAR(50)),'') + ', State ' + isnull(cast(Error_State() AS NVARCHAR(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() AS NVARCHAR(50)),'') + CHAR(10) +  Error_Message() + CHAR(10);
    END CATCH
END
GO

IF OBJECT_ID ('#sp_perf_io_snapshots','P') IS NOT NULL
DROP PROCEDURE #sp_perf_io_snapshots
GO
CREATE PROCEDURE #sp_perf_io_snapshots @appname sysname='pssdiag', @runtime DATETIME, @runtime_utc DATETIME
AS
SET NOCOUNT ON
BEGIN
    BEGIN TRY

        DECLARE @msg VARCHAR(100)
        IF NOT EXISTS (SELECT * FROM sys.dm_exec_requests req left outer join sys.dm_exec_sessions sess
                        on req.session_id = sess.session_id
                        WHERE req.session_id <> @@SPID AND ISNULL (sess.host_name, '') != @appname and is_user_process = 1) 
        BEGIN
            PRINT 'No active queries'
        END
        ELSE 
        BEGIN
            IF @runtime IS NULL or @runtime_utc IS NULL
            BEGIN 
                SET @runtime = GETDATE()
                SET @runtime_utc = GETUTCDATE()
            END
                
            PRINT ''
            PRINT '--  high_io_queries --'

            select	CONVERT (VARCHAR(30), @runtime, 126) AS runtime, CONVERT (VARCHAR(30), @runtime_utc, 126) AS runtime_utc, req.session_id, req.start_time AS request_start_time, req.cpu_time, req.total_elapsed_time, req.logical_reads,
                    req.status, req.command, req.wait_type, req.wait_time, req.scheduler_id, req.granted_query_memory, tsk.task_state, tsk.context_switches_count,
                    replace(replace(substring(ISNULL(SQLText.text, ''),1,1000),CHAR(10), ' '),CHAR(13), ' ')  AS batch_text, 
                    ISNULL(sess.program_name, '') AS program_name, ISNULL (sess.host_name, '') AS Host_name, ISNULL(sess.host_process_id,0) AS session_process_id, 
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
            FROM sys.dm_exec_requests req
                LEFT OUTER JOIN sys.dm_exec_connections conn 
                    ON conn.session_id = req.session_id
                    AND conn.net_transport <> 'session'
                OUTER APPLY sys.dm_exec_sql_text (ISNULL (req.sql_handle, conn.most_recent_sql_handle)) AS SQLText
                LEFT OUTER JOIN sys.dm_exec_sessions sess on conn.session_id = sess.session_id
                LEFT OUTER JOIN sys.dm_os_tasks tsk on sess.session_id = tsk.session_id
            WHERE sess.is_user_process = 1
            AND  wait_type IN ( 'PAGEIOLATCH_SH', 'PAGEIOLATCH_EX', 'PAGEIOLATCH_UP',	'WRITELOG','IO_COMPLETION','ASYNC_IO_COMPLETION' )
                AND wait_time >= 15
            ORDER BY req.logical_reads desc  
            OPTION (max_grant_percent = 3, MAXDOP 1)
            
            PRINT  ''
            PRINT  '--  sys.dm_io_pending_io_requests --'
        
            DECLARE @sql_major_version INT, @sql_major_build INT, @sql NVARCHAR (max)
            
            SELECT @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)), 4) AS INT))
                
            IF OBJECT_ID ('tempdb.dbo.#dm_io_pending_io_requests') IS NOT NULL 
                DROP TABLE #dm_io_pending_io_requests
            
            SELECT 
            CONVERT(VARCHAR(30), @runtime, 121) AS runtime,
            io_completion_request_address,
            io_type,
            io_pending_ms_ticks,
            io_pending,
            io_completion_routine_address,
            io_user_data_address,
            scheduler_address,
            io_handle,
            io_offset,
                CASE 
                    WHEN @sql_major_version >= 12 
                    THEN io_handle_path 
                    ELSE NULL 
                END AS io_handle_path
            INTO #dm_io_pending_io_requests
            FROM sys.dm_io_pending_io_requests

            SET @sql = N'select * from #dm_io_pending_io_requests'

            EXECUTE sp_executesql @sql,
                                N'@runtime DATETIME',
                                @runtime = @runtime;
   
            --flush results to client
            RAISERROR (' ', 0, 1) WITH NOWAIT

            PRINT  ''
            PRINT  '--  sys.dm_io_pending_io_requests Aggregated --'
            IF (@sql_major_version >=12)
            BEGIN
                SET @sql = N'SELECT CONVERT (VARCHAR(30), @runtime, 121) AS runtime,
                                io_handle_path, 
                                io_type, 
                                io_pending,
                                CASE 
                                    WHEN io_pending = 0 THEN ''Pending in SQL Server''
                                    WHEN io_pending = 1 THEN ''Pending in OS''
                                ELSE ''Unknown''
                                END AS pending_in,
                                COUNT(*) AS request_count
                                FROM #dm_io_pending_io_requests
                                GROUP BY io_handle_path, io_type, io_pending
                                ORDER BY request_count DESC'

                EXECUTE sp_executesql @sql,
                                    N'@runtime DATETIME',
                                    @runtime = @runtime;
            END

            --flush results to client
            RAISERROR (' ', 0, 1) WITH NOWAIT

        END
    
    END TRY
    BEGIN CATCH
    PRINT 'Exception occured in: `"' + OBJECT_NAME(@@PROCID)  + '`"'     
    PRINT 'Msg ' + isnull(cast(Error_Number() AS NVARCHAR(50)), '') + ', Level ' + isnull(cast(Error_Severity() AS NVARCHAR(50)),'') + ', State ' + isnull(cast(Error_State() AS NVARCHAR(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() AS NVARCHAR(50)),'') + CHAR(10) +  Error_Message() + CHAR(10);
    END CATCH
END
GO

if object_id ('#sp_run_high_io_perfstats','p') IS NOT NULL
DROP PROCEDURE #sp_run_high_io_perfstats
GO
CREATE PROCEDURE #sp_run_high_io_perfstats 
AS
    BEGIN TRY
    -- Main loop

        PRINT 'starting high io perf stats script...'
        SET LANGUAGE us_english
        PRINT '-- script source --'
        SELECT 'high io perf stats script' AS script_name
        PRINT ''
        PRINT '-- script and environment details --'
        PRINT 'name                     value'
        PRINT '------------------------ ---------------------------------------------------'
        PRINT 'sql server name          ' + @@servername
        PRINT 'machine name             ' + convert (VARCHAR, serverproperty ('machinename'))
        PRINT 'sql version (sp)         ' + convert (VARCHAR, serverproperty ('productversion')) + ' (' + convert (VARCHAR, serverproperty ('productlevel')) + ')'
        PRINT 'edition                  ' + convert (VARCHAR, serverproperty ('edition'))
        PRINT 'script begin time        ' + convert (VARCHAR(30), getdate(), 126) 
        PRINT 'current database         ' + db_name()
        PRINT '@@spid                   ' + ltrim(str(@@spid))
        PRINT ''

        DECLARE @runtime DATETIME, @runtime_utc DATETIME, @prevruntime DATETIME
        DECLARE @msg VARCHAR(100)
        DECLARE @counter BIGINT
        SELECT @prevruntime = sqlserver_start_time FROM sys.dm_os_sys_info

        --SET prevtime to 5 min earlier, in case SQL just started
        SET @prevruntime = DATEADD(SECOND, -300, @prevruntime)
        SET @counter = 0

        WHILE (1=1)
        BEGIN
            BEGIN TRY
                SET @runtime = GETDATE()
                SET @runtime_utc = GETUTCDATE()
                --SET @msg = 'Start time: ' + CONVERT (VARCHAR(30), @runtime, 126)

                PRINT ''
                RAISERROR (@msg, 0, 1) WITH NOWAIT
            
                if (@counter % 6 = 0)  -- capture this data every 1 minute
                BEGIN
                    EXEC #sp_perf_virtual_file_stats 'pssdiag', @runtime = @runtime, @runtime_utc = @runtime_utc
                END
                
                -- Collect sp_perf_high_io_snapshot every 3 minutes
                EXEC #sp_perf_io_snapshots 'pssdiag', @runtime = @runtime, @runtime_utc = @runtime_utc
                SET @prevruntime = @runtime
                WAITFOR DELAY '0:00:10'
                SET @counter = @counter + 1
            END TRY		
            BEGIN CATCH
                PRINT 'Exception occured in: `"' + OBJECT_NAME(@@PROCID)  + '`"'     
                PRINT 'Msg ' + isnull(cast(Error_Number() AS NVARCHAR(50)), '') + ', Level ' + isnull(cast(Error_Severity() AS NVARCHAR(50)),'') + ', State ' + isnull(cast(Error_State() AS NVARCHAR(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() AS NVARCHAR(50)),'') + CHAR(10) +  Error_Message() + CHAR(10);
            END CATCH			
        END
    END TRY
    BEGIN CATCH
        PRINT 'Exception occured in: `"' + OBJECT_NAME(@@PROCID)  + '`"'     
        PRINT 'Msg ' + isnull(cast(Error_Number() AS NVARCHAR(50)), '') + ', Level ' + isnull(cast(Error_Severity() AS NVARCHAR(50)),'') + ', State ' + isnull(cast(Error_State() AS NVARCHAR(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() AS NVARCHAR(50)),'') + CHAR(10) +  Error_Message() + CHAR(10);
    END CATCH	
GO

EXEC #sp_run_high_io_perfstats
    