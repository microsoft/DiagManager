    SET NOCOUNT ON

    PRINT ''
    RAISERROR ('-- DiagInfo --', 0, 1) WITH NOWAIT
    SELECT 1002 AS 'DiagVersion', '2023-12-06' AS 'DiagDate'
    PRINT ''

    PRINT 'Script Version = 1001'
    PRINT ''

    SET LANGUAGE us_english
    PRINT '-- Script and Environment Details --'
    PRINT 'Name                     Value'
    PRINT '------------------------ ---------------------------------------------------'
    PRINT 'Script Name              Misc Diagnostics Info'
    PRINT 'Script File Name         `MiscDiagInfo.sql'
    PRINT 'Revision                 '
    PRINT 'Last Modified            2023/12/06 12:04:00 EST'
    PRINT 'Script Begin Time        ' + CONVERT (VARCHAR(30), GETDATE(), 126) 
    PRINT 'Current Database         ' + DB_NAME()
    PRINT ''


    DECLARE @sql_major_version INT, @sql_major_build INT, @sql NVARCHAR(max), @sql_minor_version INT
    SELECT @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)), 4) AS INT)),
        @sql_major_build = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)), 2) AS INT)) ,
        @sql_minor_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)), 3) AS INT))

    -- ParsName is used to extract MajorVersion , MinorVersion and Build from ProductVersion e.g. 16.0.1105.1 will comeback AS 16000001105

    DECLARE @SQLVERSION BIGINT =  PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)), 4) 
                                + RIGHT(REPLICATE ('0', 3) + PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)), 3), 3)  
                                + RIGHT (replicate ('0', 6) + PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(20)), 2) , 6)



    CREATE TABLE #summary (PropertyName NVARCHAR(50) primary key, PropertyValue NVARCHAR(256))
    INSERT INTO #summary VALUES ('ProductVersion', cast (SERVERPROPERTY('ProductVersion') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('MajorVersion', LEFT(CONVERT(SYSNAME,SERVERPROPERTY('ProductVersion')), CHARINDEX('.', CONVERT(SYSNAME,SERVERPROPERTY('ProductVersion')), 0)-1))
    INSERT INTO #summary VALUES ('IsClustered', cast (SERVERPROPERTY('IsClustered') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('Edition', cast (SERVERPROPERTY('Edition') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('InstanceName', cast (SERVERPROPERTY('InstanceName') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('SQLServerName', @@SERVERNAME)
    INSERT INTO #summary VALUES ('MachineName', cast (SERVERPROPERTY('MachineName') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('ProcessID', cast (SERVERPROPERTY('ProcessID') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('ResourceVersion', cast (SERVERPROPERTY('ResourceVersion') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('ServerName', cast (SERVERPROPERTY('ServerName') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('ComputerNamePhysicalNetBIOS', cast (SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('BuildClrVersion', cast (SERVERPROPERTY('BuildClrVersion') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('IsFullTextInstalled', cast (SERVERPROPERTY('IsFullTextInstalled') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('IsIntegratedSecurityOnly', cast (SERVERPROPERTY('IsIntegratedSecurityOnly') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('ProductLevel', cast (SERVERPROPERTY('ProductLevel') AS NVARCHAR(max)))
    INSERT INTO #summary VALUES ('suser_name()', cast (SUSER_NAME() AS NVARCHAR(max)))

    INSERT INTO #summary SELECT 'number of visible schedulers', count (*) 'cnt' FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE'
    INSERT INTO #summary SELECT 'number of visible numa nodes', count (distinct parent_node_id) 'cnt' FROM sys.dm_os_schedulers WHERE status = 'VISIBLE ONLINE'
    INSERT INTO #summary SELECT 'cpu_count', cpu_count FROM sys.dm_os_sys_info
    INSERT INTO #summary SELECT 'hyperthread_ratio', hyperthread_ratio FROM sys.dm_os_sys_info
    INSERT INTO #summary SELECT 'machine start time', convert(VARCHAR(23),dateadd(SECOND, -ms_ticks/1000, GETDATE()),121) FROM sys.dm_os_sys_info
    INSERT INTO #summary SELECT 'number of tempdb data files', count (*) 'cnt' FROM master.sys.master_files WHERE database_id = 2 and [type] = 0
    INSERT INTO #summary SELECT 'number of active profiler traces',count(*) 'cnt' FROM ::fn_trace_getinfo(0) WHERE property = 5 and convert(TINYINT,value) = 1
    INSERT INTO #summary SELECT 'suser_name() default database name',default_database_name FROM sys.server_principals WHERE name = SUSER_NAME()

    INSERT INTO #summary SELECT  'VISIBLEONLINE_SCHEDULER_COUNT' PropertyName, count (*) PropertValue FROM sys.dm_os_schedulers WHERE status='VISIBLE ONLINE'
    INSERT INTO #summary SELECT 'UTCOffset_in_Hours' PropertyName, cast( datediff (MINUTE, getutcdate(), getdate()) / 60.0 AS decimal(10,2)) PropertyValue


    DECLARE @cpu_ticks BIGINT
    SELECT @cpu_ticks = cpu_ticks FROM sys.dm_os_sys_info
    WAITFOR DELAY '0:0:2'
    SELECT @cpu_ticks = cpu_ticks - @cpu_ticks FROM sys.dm_os_sys_info

    INSERT INTO #summary VALUES ('cpu_ticks_per_sec', @cpu_ticks / 2 )

    PRINT ''

    -- GO

    --removing xp_instance_regread calls & related variables as a part of issue #149
    
    DECLARE @value NVARCHAR(256)
    DECLARE @pos INT 
    
    --get windows info from dmv
    SELECT @value = windows_release FROM sys.dm_os_windows_info

    SET @pos = CHARINDEX(N'.', @value)
    IF @pos != 0
    BEGIN
        INSERT INTO #summary VALUES ('operating system version major',SUBSTRING(@value, 1, @pos-1))
        INSERT INTO #summary VALUES ('operating system version minor',SUBSTRING(@value, @pos+1, LEN(@value)))	
        
        --inserting NULL to keep same #summary structure

        INSERT INTO #summary VALUES ('operating system version build', NULL)
        
        INSERT INTO #summary VALUES ('operating system', NULL)	

        INSERT INTO #summary VALUES ('operating system install date',NULL)
    
    END
    
        --inserting NULL to keep same #summary structure 
        INSERT INTO #summary VALUES ('registry SystemManufacturer', NULL)

        INSERT INTO #summary VALUES ('registry SystemProductName', NULL)	

        INSERT INTO #summary VALUES ('registry ActivePowerScheme (default)', NULL)	

        INSERT INTO #summary VALUES ('registry ActivePowerScheme', NULL)	

        --inserting OS Edition and Build from @@Version 
        INSERT INTO #summary VALUES ('OS Edition and Build from @@Version',  REPLACE(LTRIM(SUBSTRING(@@VERSION,CHARINDEX(' on ',@@VERSION)+3,100)),CHAR(10),''))
    

    IF (@SQLVERSION >= 10000001600) --10.0.1600
    BEGIN
        EXEC sp_executesql N'INSERT INTO #summary SELECT ''sqlserver_start_time'', convert(VARCHAR(23),sqlserver_start_time,121) FROM sys.dm_os_sys_info'
        EXEC sp_executesql N'INSERT INTO #summary SELECT ''resource governor enabled'', is_enabled FROM sys.resource_governor_configuration'
        INSERT INTO #summary VALUES ('FilestreamShareName', cast (SERVERPROPERTY('FilestreamShareName') AS NVARCHAR(max)))
        INSERT INTO #summary VALUES ('FilestreamConfiguredLevel', cast (SERVERPROPERTY('FilestreamConfiguredLevel') AS NVARCHAR(max)))
        INSERT INTO #summary VALUES ('FilestreamEffectiveLevel', cast (SERVERPROPERTY('FilestreamEffectiveLevel') AS NVARCHAR(max)))
        INSERT INTO #summary SELECT 'number of active extENDed event traces',count(*) AS 'cnt' FROM sys.dm_xe_sessions
    END

    IF (@SQLVERSION >= 10050001600) --10.50.1600
    BEGIN
        EXEC sp_executesql N'INSERT INTO #summary SELECT ''possibly running in virtual machine'', virtual_machine_type FROM sys.dm_os_sys_info'
    END

    IF (@SQLVERSION >= 11000002100) --11.0.2100
    BEGIN
        EXEC sp_executesql N'INSERT INTO #summary SELECT ''physical_memory_kb'', physical_memory_kb FROM sys.dm_os_sys_info'
        INSERT INTO #summary VALUES ('HadrManagerStatus', cast (SERVERPROPERTY('HadrManagerStatus') AS NVARCHAR(max)))
        INSERT INTO #summary VALUES ('IsHadrEnabled', cast (SERVERPROPERTY('IsHadrEnabled') AS NVARCHAR(max)))	
    END

    IF (@SQLVERSION >= 14000001000) --14.0.1000.169	- SQL 2017 RTM
    OR (@SQLVERSION BETWEEN 13000004001 AND 13999999999) --13.0.4001.0 - SQL 2016 SP1
    OR (@SQLVERSION BETWEEN 12000006024 AND 12999999999) --12.0.6024.0 - SQL 2014 SP3
    OR (@SQLVERSION BETWEEN 11000007001 AND 11999999999) --11.0.7001 - SQL 2012 SP4
    BEGIN
        EXEC sp_executesql N'INSERT INTO #summary SELECT ''instant_file_initialization_enabled'', instant_file_initialization_enabled FROM sys.dm_server_services WHERE process_id = SERVERPROPERTY(''ProcessID'')'
    END

    IF (@SQLVERSION >= 12000002000) --12.0.2000
    BEGIN
        INSERT INTO #summary VALUES ('IsLocalDB', cast (SERVERPROPERTY('IsLocalDB') AS NVARCHAR(max)))
        INSERT INTO #summary VALUES ('IsXTPSupported', cast (SERVERPROPERTY('IsXTPSupported') AS NVARCHAR(max)))
    END

    RAISERROR ('--ServerProperty--', 0, 1) WITH NOWAIT

    SELECT * FROM #summary
    ORDER BY PropertyName
    DROP TABLE #summary
    PRINT ''

    --GO
    --changing xp_instance_regenumvalues to dmv access as a part of issue #149

    DECLARE @startup table (ArgsName NVARCHAR(10), ArgsValue NVARCHAR(max))
    INSERT INTO @startup 
    SELECT     sReg.value_name,     CAST(sReg.value_data AS NVARCHAR(max))
    FROM sys.dm_server_registry AS sReg
    WHERE     sReg.value_name LIKE N'SQLArg%';

    RAISERROR ('--Startup Parameters--', 0, 1) WITH NOWAIT
    SELECT * FROM @startup

    PRINT ''

    CREATE TABLE #traceflg (TraceFlag INT, Status INT, Global INT, Session INT)
    INSERT INTO #traceflg EXEC ('dbcc tracestatus (-1)')
    PRINT ''
    RAISERROR ('--traceflags--', 0, 1) WITH NOWAIT
    SELECT * FROM #traceflg
    DROP TABLE #traceflg


    PRINT ''
    RAISERROR ('--sys.dm_os_schedulers--', 0, 1) WITH NOWAIT
    SELECT * FROM sys.dm_os_schedulers


    PRINT ''
    RAISERROR ('-- sys.dm_os_loaded_modules --', 0, 1) WITH NOWAIT
            SELECT base_address      , 
                file_version, 
                product_version, 
                debug, 
                patched, 
                prerelease, 
                private_build, 
                special_build, 
                [language], 
                company, 
                [description], 
                [name]
            FROM sys.dm_os_loaded_modules
            PRINT ''


    IF (@SQLVERSION >= 10000001600 --10.0.1600
        and @SQLVERSION < 10050000000) --10.50.0.0
    BEGIN
        PRINT ''
        RAISERROR ('--sys.dm_os_nodes--', 0, 1) WITH NOWAIT
        EXEC sp_executesql N'SELECT node_id, memory_object_address, memory_clerk_address, io_completion_worker_address, memory_node_id, cpu_affinity_mask, online_scheduler_count, idle_scheduler_count active_worker_count, avg_load_balance, timer_task_affinity_mask, permanent_task_affinity_mask, resource_monitor_state, node_state_desc FROM sys.dm_os_nodes'
    END


    IF (@SQLVERSION >= 10050000000) --10.50.0.0
    BEGIN
        PRINT ''
        RAISERROR ('--sys.dm_os_nodes--', 0, 1) WITH NOWAIT
        EXEC sp_executesql N'SELECT node_id, memory_object_address, memory_clerk_address, io_completion_worker_address, memory_node_id, cpu_affinity_mask, online_scheduler_count, idle_scheduler_count active_worker_count, avg_load_balance, timer_task_affinity_mask, permanent_task_affinity_mask, resource_monitor_state, online_scheduler_mask, processor_group, node_state_desc FROM sys.dm_os_nodes'
    END


    PRINT ''
    RAISERROR ('--dm_os_sys_info--', 0, 1) WITH NOWAIT
    SELECT * FROM sys.dm_os_sys_info


    if cast (SERVERPROPERTY('IsClustered') AS INT) = 1
    BEGIN
        PRINT ''
        RAISERROR ('--fn_virtualservernodes--', 0, 1) WITH NOWAIT
        SELECT * FROM fn_virtualservernodes()
    END



    PRINT ''
    RAISERROR ('--sys.configurations--', 0, 1) WITH NOWAIT
    SELECT configuration_id, 
    convert(INT,value) AS 'value', 
    convert(INT,value_in_use) AS 'value_in_use', 
    convert(INT,minimum) AS 'minimum', 
    convert(INT,maximum) AS 'maximum', 
    convert(INT,is_dynamic) AS 'is_dynamic', 
    convert(INT,is_advanced) AS 'is_advanced', 
    name  
    FROM sys.configurations 
    ORDER BY name


    PRINT ''
    RAISERROR ('--database files--', 0, 1) WITH NOWAIT
    SELECT database_id, [file_id], file_guid, [type],  LEFT(type_desc,10) AS 'type_desc', data_space_id, [state], LEFT(state_desc,16) AS 'state_desc', size, max_size, growth,
    is_media_read_only, is_read_only, is_sparse, is_percent_growth, is_name_reserved, create_lsn,  drop_lsn, read_only_lsn, read_write_lsn, differential_base_lsn, differential_base_guid,
    differential_base_time, redo_start_lsn, redo_start_fork_guid, redo_target_lsn, redo_target_fork_guid, backup_lsn, db_name(database_id) AS 'Database_name',  name, physical_name 
    FROM master.sys.master_files ORDER BY database_id, type, file_id

    PRINT ''
    RAISERROR ('-- sysaltfiles--', 0, 1) WITH NOWAIT
    SELECT af.dbid as [dbid],  db_name(af.dbid) as [database_name], fileid, groupid, [size], [maxsize], [growth], [status],rtrim(af.filename) as [filename],rtrim(af.name) as [filename]
    FROM master.sys.sysaltfiles af
    WHERE af.dbid != db_id('tempdb')
    ORDER BY af.dbid,af.fileid

    PRINT ''
    RAISERROR ('--sys.databases_ex--', 0, 1) WITH NOWAIT
    SELECT cast(DATABASEPROPERTYEX (name,'IsAutoCreateStatistics') AS INT) 'IsAutoCreateStatistics', cast( DATABASEPROPERTYEX (name,'IsAutoUpdateStatistics') AS INT) 'IsAutoUpdateStatistics', cast (DATABASEPROPERTYEX (name,'IsAutoCreateStatisticsIncremental') AS INT) 'IsAutoCreateStatisticsIncremental', *  FROM sys.databases

    PRINT ''
    RAISERROR ('-- Windows Group Default Databases other than master --', 0, 1) WITH NOWAIT
    SELECT name,default_database_name FROM sys.server_principals WHERE [type] = 'G' and is_disabled = 0 and default_database_name != 'master'

    --removed AG related dmvs as a part of issue #162
    PRINT ''
    PRINT '-- sys.change_tracking_databases --'
    SELECT * FROM sys.change_tracking_databases


    PRINT ''
    PRINT '-- sys.dm_database_encryption_keys --'
    SELECT database_id, encryption_state FROM sys.dm_database_encryption_keys



    PRINT ''
    IF @SQLVERSION >= 15000002000 --15.0.2000
    BEGIN
        PRINT '-- sys.dm_tran_persistent_version_store_stats --'
        SELECT * FROM sys.dm_tran_persistent_version_store_stats
        PRINT ''
    END


    PRINT '-- sys.certificates --' 
    SELECT
        CONVERT(VARCHAR(64),DB_NAME())  AS [database_name], 
        name,
        certificate_id,
        principal_id,
        pvt_key_encryption_type,
        CONVERT(VARCHAR(32), pvt_key_encryption_type_desc) AS pvt_key_encryption_type_desc,
        is_active_for_begin_dialog,
        CONVERT(VARCHAR(512), issuer_name) AS issuer_name,
        cert_serial_number,
        sid,
        string_sid,
        CONVERT(VARCHAR(512),subject) AS subject,
        expiry_date,
        start_date,
        '0x' + CONVERT(VARCHAR(64),thumbprint,2) AS thumbprint,
        CONVERT(VARCHAR(256), attested_by) AS attested_by,
        pvt_key_last_backup_date
    FROM master.sys.certificates 
    PRINT ''


    PRINT '-- sys.servers --'
    SELECT [server_id]
      ,[name]
      ,[product]
      ,[provider]
      ,CONVERT(VARCHAR(512),[data_source]) AS [data_source]
      ,CONVERT(VARCHAR(512),[location]) AS [location]
      ,CONVERT(VARCHAR(512),[provider_string]) AS [provider_string]
      ,[catalog]
      ,[connect_timeout]
      ,[query_timeout]
      ,[is_linked]
      ,[is_remote_login_enabled]
      ,[is_rpc_out_enabled]
      ,[is_data_access_enabled]
      ,[is_collation_compatible]
      ,[uses_remote_collation]
      ,[collation_name]
      ,[lazy_schema_validation]
      ,[is_system]
      ,[is_publisher]
      ,[is_subscriber]
      ,[is_distributor]
      ,[is_nonsql_subscriber]
      ,[is_remote_proc_transaction_promotion_enabled]
      ,[modify_date]
    FROM [master].[sys].[servers]
    PRINT '' 

    --this proc is only present in SQL Server 2019 and later but seems not present in early builds
    IF OBJECT_ID('sys.sp_certificate_issuers') IS NOT NULL
    BEGIN

        CREATE TABLE #certificate_issuers(
                certificateid INT,
                dnsname NVARCHAR(128) )

        INSERT INTO #certificate_issuers
        EXEC ('EXEC sys.sp_certificate_issuers')

        PRINT '-- sys_sp_certificate_issuers --'
        
        SELECT certificateid, dnsname 
        FROM #certificate_issuers

        DROP TABLE #certificate_issuers
    END
    PRINT ''
    PRINT ''


    -- Collect db_log_info to check for VLF issues
    --this table to be used by older versions of SQL Server prior to 2016 SP2
    CREATE TABLE #dbcc_loginfo_cur_db
    (
        RecoveryUnitId INT,
        FileId      INT,
        FileSize    BIGINT,
        StartOffset  BIGINT,
        FSeqNo      BIGINT,
        Status      INT,
        Parity		INT,
        CreateLSN	NVARCHAR(48)
    )
    --this table contains all the results
    CREATE TABLE #loginfo_all_dbs
    (
        database_id	INT,
        [database_name] VARCHAR(64),
        vlf_count INT,
        vlf_avg_size_mb	DECIMAL(10,2),
        vlf_min_size_mb DECIMAL(10,2),
        vlf_max_size_mb DECIMAL(10,2),
        vlf_status INT,
        vlf_active BIT
    )

    DECLARE @dbname NVARCHAR(64), @dbid INT
    DECLARE @dbcc_log_info VARCHAR(MAX)

    DECLARE Database_Cursor CURSOR FOR SELECT database_id, name FROM master.sys.databases

    OPEN Database_Cursor;

    FETCH NEXT FROM Database_Cursor INTO @dbid, @dbname;

    WHILE @@FETCH_STATUS = 0
        BEGIN

            SET @dbcc_log_info = 'DBCC LOGINFO (''' + @dbname + ''') WITH NO_INFOMSGS'
            
            IF ((@sql_major_version >= 14) or (@sql_major_version >= 13) and (@sql_major_build >= 5026 ))
            BEGIN
            
                INSERT INTO #loginfo_all_dbs(
                    database_id	,
                    database_name ,
                    vlf_count,
                    vlf_avg_size_mb	,
                    vlf_min_size_mb,
                    vlf_max_size_mb,
                    vlf_status ,
                    vlf_active)
                SELECT 
                    database_id,
                    @dbname,
                    count(*) AS vlf_count,
                    AVG(vlf_size_mb) AS vlf_avg_size_mb,
                    MIN(vlf_size_mb) AS vlf_min_size_mb,
                    MAX(vlf_size_mb) AS vlf_max_size_mb,
                    vlf_status,
                    vlf_active
                FROM sys.dm_db_log_info (db_id(@dbname))
                GROUP BY database_id, vlf_status, vlf_active

            END
            ELSE
            --if version is prior to SQL 2016 SP2, use DBCC LOGINFO to get the data
            --but insert and format it into a table as if it came from sys.dm_db_log_info
            BEGIN
                INSERT INTO #dbcc_loginfo_cur_db (
                    RecoveryUnitId ,
                    FileId      ,
                    FileSize    ,
                    StartOffset ,
                    FSeqNo      ,
                    Status      ,
                    Parity		,
                    CreateLSN)
                EXEC(@dbcc_log_info)

                
                INSERT INTO #loginfo_all_dbs(
                    database_id	,
                    database_name ,
                    vlf_count ,
                    vlf_avg_size_mb	,
                    vlf_min_size_mb,
                    vlf_max_size_mb,
                    vlf_status ,
                    vlf_active )
            --do the formatting to match the sys.dm_db_log_info standard as much as possible	
                SELECT 
                    @dbid, 
                    @dbname, 
                    COUNT(li.FSeqNo) AS vlf_count,
                    CONVERT(DECIMAL(10,2),AVG(li.FileSize/1024/1024.0)) AS vlf_avg_size_mb,
                    CONVERT(DECIMAL(10,2),MIN(li.FileSize/1024/1024.0)) AS vlf_min_size_mb,
                    CONVERT(DECIMAL(10,2),MAX(li.FileSize/1024/1024.0)) AS vlf_max_size_mb,
                    li.Status,
                    CASE WHEN li.Status = 2 THEN 1 ELSE 0 END AS Active
                FROM #dbcc_loginfo_cur_db li
                GROUP BY Status, CASE WHEN li.Status = 2 THEN 1 ELSE 0 END 

                --clean up the temp table for next loop
                TRUNCATE TABLE #dbcc_loginfo_cur_db
            END

            FETCH NEXT FROM Database_Cursor INTO @dbid, @dbname;

        END;
    CLOSE Database_Cursor;
    DEALLOCATE Database_Cursor;

    PRINT '-- sys_dm_db_log_info --'
    SELECT 
        database_id	,
        database_name ,
        vlf_count ,
        vlf_avg_size_mb	,
        vlf_min_size_mb	,
        vlf_max_size_mb	,
        vlf_status ,
        vlf_active 
    FROM #loginfo_all_dbs
    ORDER BY database_name


    DROP TABLE #dbcc_loginfo_cur_db
    DROP TABLE #loginfo_all_dbs
    PRINT ''

    PRINT '-- sql_agent_jobs_information --'; 
WITH LastExecution AS (
    SELECT ROW_NUMBER() OVER (PARTITION  BY job_id ORDER BY run_date DESC, run_time  DESC) as id,
	       job_id,
	       run_date,
		   run_time,
		   run_status
    FROM msdb.dbo.sysjobhistory
    WHERE step_id = 0
    )
    SELECT sj.name AS JobName, 
        CASE sj.enabled 
         WHEN 1 THEN 'Yes'
         ELSE 'No'
        END AS IsEnabled,
        CASE ss.enabled
         WHEN 1 THEN 'Yes'
         ELSE 'No'
        END AS ScheduleEnabled,
        CASE ss.freq_type
         WHEN 1 THEN 'Once'
         WHEN 4 THEN 'Daily'
         WHEN 8 THEN 'Weekly'
         WHEN 16 THEN 'Monthly'
         WHEN 32 THEN 'Monthly - Interval Related' 
         WHEN 64 THEN 'When Agent Starts'
         WHEN 128 THEN 'When Computer is Idle'
        END AS Frequency, 
        CASE ss.freq_subday_type
         WHEN 0 THEN 'N/A'
         WHEN 1 THEN 'Specific Time'
         WHEN 2 THEN 'Seconds'
         WHEN 4 THEN 'Minutes'
         WHEN 8 THEN 'Hours'
        END AS IntervalType,
        CASE
         WHEN ss.freq_subday_type = 1 THEN LEFT(STUFF(STUFF(STUFF(CONVERT(VARCHAR(6), active_start_time), 1, 0,
                                          REPLICATE('0', 6 - LEN(CONVERT(VARCHAR(6), active_start_time)))), 3, 0, ':'), 6, 0, ':'), 12)
         ELSE 'N/A'
        END AS ExecutionTime,
        CASE 
         WHEN ss.freq_type = 1 THEN 'N/A'
         WHEN ss.freq_type = 64 THEN 'N/A'
         WHEN ss.freq_type = 16 THEN 'N/A'
         WHEN ss.freq_type = 4 THEN 'Every ' + CONVERT(VARCHAR(10), ss.freq_relative_interval) + ' day(s)' 
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 1 THEN 'Sunday' 
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 2 THEN 'Monday' 
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 4 THEN 'Tuesday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 8 THEN 'Wednesday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 16 THEN 'Thursday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 32 THEN 'Friday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 62 THEN 'Monday to Saturday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 64 THEN 'Saturday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 65 THEN 'Saturday, Sunday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 124 THEN 'Tuesday to Sunday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 126 THEN 'Monday to Sunday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 127 THEN 'Monday to Sunday (All days)'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 9 THEN 'Wednesday, Sunday'
         WHEN ss.freq_type = 8 AND ss.freq_relative_interval = 95 THEN 'Monday, Tuesday, Wednesday, Thursday, Saturday, Sunday'
         WHEN ss.freq_type = 8 THEN 'Every ' + CONVERT(VARCHAR(20), ss.freq_recurrence_factor) + ' Week'
         WHEN ss.freq_type = 16 THEN 'Every ' + CONVERT(VARCHAR(20), ss.freq_recurrence_factor) + ' Month'
         WHEN ss.freq_type = 32 THEN 'Every ' + CONVERT(VARCHAR(20), ss.freq_recurrence_factor) + ' Month'
         ELSE 'N/A'
        END AS Interval,
        CASE
         WHEN ss.freq_subday_type = 1 THEN 'N/A'
         WHEN ss.freq_subday_type = 2 THEN 'Every ' + CONVERT(VARCHAR(20), ss.freq_subday_interval) + ' second(s)'
         WHEN ss.freq_subday_type = 4 THEN 'Every ' + CONVERT(VARCHAR(20), ss.freq_subday_interval) + ' minute(s)'
         WHEN ss.freq_subday_type = 8 THEN 'Every ' + CONVERT(VARCHAR(20), ss.freq_subday_interval) + ' hour(s)'
         ELSE 'N/A'
        END AS DayInterval,
        CASE 
         WHEN ss.freq_type = 16 THEN CONVERT(VARCHAR(2), ss.freq_relative_interval)
         WHEN ss.freq_type = 32 AND ss.freq_interval = 1 AND ss.freq_relative_interval = 1 THEN 'First Sunday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 2 AND ss.freq_relative_interval = 1 THEN 'First Monday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 3 AND ss.freq_relative_interval = 1 THEN 'First Tuesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 4 AND ss.freq_relative_interval = 1 THEN 'First Wednesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 5 AND ss.freq_relative_interval = 1 THEN 'First Thursday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 6 AND ss.freq_relative_interval = 1 THEN 'First Friday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 7 AND ss.freq_relative_interval = 1 THEN 'First Saturday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 8 AND ss.freq_relative_interval = 1 THEN 'First day of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 9 AND ss.freq_relative_interval = 1 THEN 'First weekday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 10 AND ss.freq_relative_interval = 1 THEN 'First weekend day of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 1 AND ss.freq_relative_interval = 2 THEN 'Second Sunday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 2 AND ss.freq_relative_interval = 2 THEN 'Second Monday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 3 AND ss.freq_relative_interval = 2 THEN 'Second Tuesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 4 AND ss.freq_relative_interval = 2 THEN 'Second Wednesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 5 AND ss.freq_relative_interval = 2 THEN 'Second Thursday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 6 AND ss.freq_relative_interval = 2 THEN 'Second Friday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 7 AND ss.freq_relative_interval = 2 THEN 'Second Saturday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 8 AND ss.freq_relative_interval = 2 THEN 'Second day of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 9 AND ss.freq_relative_interval = 2 THEN 'Second weekday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 10 AND ss.freq_relative_interval = 2 THEN 'Second weekend day of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 1 AND ss.freq_relative_interval = 4 THEN 'Third Sunday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 2 AND ss.freq_relative_interval = 4 THEN 'Third Monday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 3 AND ss.freq_relative_interval = 4 THEN 'Third Tuesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 4 AND ss.freq_relative_interval = 4 THEN 'Third Wednesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 5 AND ss.freq_relative_interval = 4 THEN 'Third Thursday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 6 AND ss.freq_relative_interval = 4 THEN 'Third Friday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 7 AND ss.freq_relative_interval = 4 THEN 'Third Saturday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 8 AND ss.freq_relative_interval = 4 THEN 'Third day of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 9 AND ss.freq_relative_interval = 4 THEN 'Third weekday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 10 AND ss.freq_relative_interval = 4 THEN 'Third weekend day of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 1 AND ss.freq_relative_interval = 8 THEN 'Fourth Sunday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 2 AND ss.freq_relative_interval = 8 THEN 'Fourth Monday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 3 AND ss.freq_relative_interval = 8 THEN 'Fourth Tuesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 4 AND ss.freq_relative_interval = 8 THEN 'Fourth Wednesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 5 AND ss.freq_relative_interval = 8 THEN 'Fourth Thursday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 6 AND ss.freq_relative_interval = 8 THEN 'Fourth Friday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 7 AND ss.freq_relative_interval = 8 THEN 'Fourth Saturday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 8 AND ss.freq_relative_interval = 8 THEN 'Fourth day of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 9 AND ss.freq_relative_interval = 8 THEN 'Fourth weekday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 10 AND ss.freq_relative_interval = 8 THEN 'Fourth weekend day of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 1 AND ss.freq_relative_interval = 16 THEN 'Last Sunday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 2 AND ss.freq_relative_interval = 16 THEN 'Last Monday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 3 AND ss.freq_relative_interval = 16 THEN 'Last Tuesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 4 AND ss.freq_relative_interval = 16 THEN 'Last Wednesday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 5 AND ss.freq_relative_interval = 16 THEN 'Last Thursday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 6 AND ss.freq_relative_interval = 16 THEN 'Last Friday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 7 AND ss.freq_relative_interval = 16 THEN 'Last Saturday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 8 AND ss.freq_relative_interval = 16 THEN 'Last day of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 9 AND ss.freq_relative_interval = 16 THEN 'Last weekday of every month'
         WHEN ss.freq_type = 32 AND ss.freq_interval = 10 AND ss.freq_relative_interval = 16 THEN 'Last weekend day of every month'
         ELSE 'N/A'
        END AS MonthDay,      
        CONVERT(VARCHAR(10), CONVERT(DATETIME, CONVERT(VARCHAR(10), active_start_date)), 126) AS StartDate,
        CONVERT(VARCHAR(10), CONVERT(DATETIME, CONVERT(VARCHAR(10), active_end_date)), 126) AS EndDate,
        LEFT(STUFF(STUFF(STUFF(CONVERT(VARCHAR(6), active_start_time), 1, 0, REPLICATE('0', 6 - LEN(CONVERT(VARCHAR(6), active_start_time)))), 3, 0, ':'), 6, 0, ':'), 12) AS StartTime,
        LEFT(STUFF(STUFF(STUFF(CONVERT(VARCHAR(6), active_end_time), 1, 0, REPLICATE('0', 6 - LEN(CONVERT(VARCHAR(6), active_end_time)))), 3, 0, ':'), 6, 0, ':'), 12) AS EndTime,
        CASE le.run_status
           WHEN 0 THEN 'Failed'
           WHEN 1 THEN 'Succeeded'
           WHEN 2 THEN 'Retry'
           WHEN 3 THEN 'Canceled'
           WHEN 4 THEN 'In Progress'
		   ELSE 'Unknown'
       END as LastExecutionStatus,
		CONVERT(date, CONVERT(varchar(10), le.run_date)) AS LastExecutionDate,
        STUFF(STUFF(RIGHT('000000' + CAST(le.run_time AS VARCHAR(6)), 6), 5, 0, ':'), 3, 0, ':') AS LastExecutionTime
    FROM msdb..sysjobs sj
    LEFT OUTER JOIN msdb..sysjobschedules sjs 
        ON (sj.job_id = sjs.job_id)
    LEFT OUTER JOIN msdb..sysschedules ss 
        ON (sjs.schedule_id = ss.schedule_id)
    LEFT OUTER JOIN LastExecution le 
        ON sj.job_id = le.job_id AND
		   le.id = 1
    ORDER BY sj.name
    OPTION (MAX_GRANT_PERCENT = 3, MAXDOP 1);

    PRINT ''
    PRINT '-- sql_agent_job_history --'
    SELECT 
        j.name AS job_name,
        h.job_id,
        h.step_id,
        h.step_name,
        h.sql_message_id,
        h.sql_severity,
        h.message,
        h.run_status,
        h.run_date,
        h.run_time,
        h.run_duration,
        h.operator_id_emailed,
        h.operator_id_netsent,
        h.operator_id_paged,
        h.retries_attempted,
        h.server,
        h.instance_id
    FROM (
        SELECT TOP 1000 *
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY run_date DESC, run_time DESC) AS rn
            FROM msdb.dbo.sysjobhistory
        ) AS JobHistory
        WHERE rn <= 100
    ) AS h
    JOIN msdb.dbo.sysjobs AS j
    ON h.job_id = j.job_id
    ORDER BY h.run_date DESC, h.run_time DESC;

    PRINT ''
    PRINT '-- sys.dm_clr_appdomains --'
    SELECT TOP 1000 
        appdomain_address,
        appdomain_id,
        LEFT(appdomain_name, 80) AS appdomain_name,
        creation_time,
        db_id,
        user_id,
        LEFT(state, 48) AS state,
        strong_refcount,
        weak_refcount,
        cost,
        value,
        compatibility_level,
        total_processor_time_ms,
        total_allocated_memory_kb,
        survived_memory_kb
    FROM sys.dm_clr_appdomains
    IF @@ROWCOUNT >= 1000 PRINT '<<<<< LIMIT OF 1000 ROWS EXCEEDED, SOME RESULTS NOT SHOWN >>>>>'
    PRINT ''
    
    PRINT '-- sys.dm_clr_loaded_assemblies --'
    SELECT TOP 1000 
        assembly_id,         
        appdomain_address,   
        load_time
    FROM sys.dm_clr_loaded_assemblies
    IF @@rowcount >= 1000 PRINT '<<<<< LIMIT OF 1000 ROWS EXCEEDED, SOME RESULTS NOT SHOWN >>>>>'
    PRINT ''


    PRINT '-- sys.dm_clr_tasks --'
    SELECT TOP 1000
        task_address,
        sos_task_address,
        appdomain_address,
        LEFT(state,64) AS state,   
        LEFT(abort_state,64) AS abort_state,
        LEFT(type,64) AS type,         
        affinity_count,
        forced_yield_count
    FROM sys.dm_clr_tasks
    IF @@rowcount >= 1000 PRINT '<<<<< LIMIT OF 1000 ROWS EXCEEDED, SOME RESULTS NOT SHOWN >>>>>'
    PRINT ''

 	-- Create temporary tables to store the results for sys.assemblies, sys.assembly_modules, and sys.assembly_types
    CREATE TABLE #assemblies (
        database_name NVARCHAR(128),
        name SYSNAME NULL,
        assembly_id INT,
        principal_id INT,
        clr_name NVARCHAR(512) NULL,
        permission_set TINYINT NULL,
        permission_set_desc NVARCHAR(128) NULL,
        is_visible BIT,
        create_date DATETIME,
        modify_date DATETIME,
        is_user_defined BIT  NULL
    );

    CREATE TABLE #assembly_modules (
        database_name NVARCHAR(128),
        object_id INT,
        assembly_id INT,
        assembly_class NVARCHAR(256) NULL,
        assembly_method NVARCHAR(256) NULL,
        null_on_null_input BIT NULL,
        execute_as_principal_id INT  NULL
    );

    CREATE TABLE #assembly_types (
        database_name NVARCHAR(128),
        name SYSNAME,
        system_type_id TINYINT,
        user_type_id INT,
        schema_id INT,
        principal_id INT NULL,
        max_length SMALLINT,
        precision TINYINT,
        scale TINYINT,
        collation_name SYSNAME NULL,
        is_nullable BIT NULL,
        is_user_defined BIT,
        is_assembly_type BIT,
        default_object_id INT,
        rule_object_id INT,
        assembly_id INT,
        assembly_class NVARCHAR(256) NULL,
        is_binary_ordered BIT NULL,
        is_fixed_length BIT NULL,
        prog_id NVARCHAR(80) NULL,
        assembly_qualified_name NVARCHAR(512) NULL,
        is_table_type BIT
    );

    -- Declare a variable to store the database name
    DECLARE @database_name NVARCHAR(128);

    -- Declare a table variable to store the list of databases
    DECLARE @databases TABLE (database_name NVARCHAR(128));

    -- Insert the list of databases into the table variable
    INSERT INTO @databases (database_name)
    SELECT name
    FROM sys.databases
    WHERE state_desc = 'ONLINE' AND name NOT IN ('master', 'tempdb', 'model', 'msdb');

    -- Loop through each database and insert the assemblies, assembly modules, and assembly types into the temporary tables
    WHILE EXISTS (SELECT 1 FROM @databases)
    BEGIN
        -- Get the next database name
        SELECT TOP 1 @database_name = database_name
        FROM @databases;

        -- Construct the dynamic SQL to insert the assemblies into the temporary table
        DECLARE @SQLTxt NVARCHAR(MAX) = '
            INSERT INTO #assemblies (database_name, assembly_id, name, principal_id, clr_name, permission_set, permission_set_desc, is_visible, create_date, modify_date, is_user_defined)
            SELECT ''' + @database_name + ''', assembly_id, name, principal_id, clr_name, permission_set, permission_set_desc, is_visible, create_date, modify_date, is_user_defined
            FROM ' + QUOTENAME(@database_name) + '.sys.assemblies
            WHERE assembly_id <> 1';

        EXEC sp_executesql @SQLTxt;

        -- Construct the dynamic SQL to insert the assembly modules into the temporary table
        SET @SQLTxt = '
            INSERT INTO #assembly_modules (database_name, object_id, assembly_id, assembly_class, assembly_method, null_on_null_input, execute_as_principal_id)
            SELECT ''' + @database_name + ''', object_id, assembly_id, assembly_class, assembly_method, null_on_null_input, execute_as_principal_id
            FROM ' + QUOTENAME(@database_name) + '.sys.assembly_modules';

        EXEC sp_executesql @SQLTxt;

        -- Construct the dynamic SQL to insert the assembly types into the temporary table
        SET @SQLTxt = '
            INSERT INTO #assembly_types (database_name, name, system_type_id, user_type_id, schema_id, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, assembly_id, assembly_class, is_binary_ordered, is_fixed_length, prog_id, assembly_qualified_name, is_table_type)
            SELECT ''' + @database_name + ''', name, system_type_id, user_type_id, schema_id, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, assembly_id, assembly_class, is_binary_ordered, is_fixed_length, prog_id, assembly_qualified_name, is_table_type
            FROM ' + QUOTENAME(@database_name) + '.sys.assembly_types
            WHERE schema_id <> SCHEMA_ID(''sys'')';

        EXEC sp_executesql @SQLTxt;

        -- Remove the processed database from the table variable
        DELETE FROM @databases
        WHERE database_name = @database_name;
    END;

    -- Select the results from the temporary tables
    PRINT '-- sys.assemblies --'
    SELECT * FROM #assemblies;
    PRINT ''

    PRINT '-- sys.assembly_modules --'
    SELECT * FROM #assembly_modules;
    PRINT ''

    PRINT '-- sys.assembly_types --'
    SELECT * FROM #assembly_types;
    PRINT ''

    -- Drop the temporary tables
    DROP TABLE #assemblies;
    DROP TABLE #assembly_modules;
    DROP TABLE #assembly_types;

    PRINT ''