set nocount on
go
print ''
RAISERROR ('-- DiagInfo --', 0, 1) WITH NOWAIT
select 1001 as 'DiagVersion', '2015-01-09' as 'DiagDate'
print ''
go
print 'Script Version = 1001'
print ''
go
SET LANGUAGE us_english
PRINT '-- Script and Environment Details --'
PRINT 'Name                     Value'
PRINT '------------------------ ---------------------------------------------------'
PRINT 'Script Name              Misc Pssdiag Info'
PRINT 'Script File Name         $File: MiscPssdiagInfo.sql $'
PRINT 'Revision                 $Revision: 1 $ ($Change: ? $)'
PRINT 'Last Modified            $Date: 2015/01/26 12:04:00 EST $'
PRINT 'Script Begin Time        ' + CONVERT (varchar(30), GETDATE(), 126) 
PRINT 'Current Database         ' + DB_NAME()
PRINT ''
GO
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
insert into #summary values ('suser_name()', cast (SUSER_NAME() as nvarchar(max)))

insert into #summary select 'number of visible schedulers', count (*) 'cnt' from sys.dm_os_schedulers where status = 'VISIBLE ONLINE'
insert into #summary select 'number of visible numa nodes', count (distinct parent_node_id) 'cnt' from sys.dm_os_schedulers where status = 'VISIBLE ONLINE'
insert into #summary select 'cpu_count', cpu_count from sys.dm_os_sys_info
insert into #summary select 'hyperthread_ratio', hyperthread_ratio from sys.dm_os_sys_info
insert into #summary select 'machine start time', convert(varchar(23),dateadd(SECOND, -ms_ticks/1000, GETDATE()),121) from sys.dm_os_sys_info
insert into #summary select 'number of tempdb data files', count (*) 'cnt' from master.sys.master_files where database_id = 2 and [type] = 0
insert into #summary select 'number of active profiler traces',count(*) 'cnt' from ::fn_trace_getinfo(0) where property = 5 and convert(tinyint,value) = 1
insert into #summary select 'suser_name() default database name',default_database_name from sys.server_principals where name = SUSER_NAME()

insert into #summary select  'VISIBLEONLINE_SCHEDULER_COUNT' PropertyName, count (*) PropertValue from sys.dm_os_schedulers where status='VISIBLE ONLINE'
insert into #summary select 'UTCOffset_in_Hours' PropertyName, cast( datediff (MINUTE, getutcdate(), getdate()) / 60.0 as decimal(10,2)) PropertyValue


declare @cpu_ticks bigint
select @cpu_ticks = cpu_ticks from sys.dm_os_sys_info
waitfor delay '0:0:2'
select @cpu_ticks = cpu_ticks - @cpu_ticks from sys.dm_os_sys_info

insert into #summary values ('cpu_ticks_per_sec', @cpu_ticks / 2 )

PRINT ''
PRINT ''
RAISERROR ('--ServerProperty--', 0, 1) WITH NOWAIT

select * from #summary
order by PropertyName

truncate table #summary

go

PRINT ''

go



--we need to get this into a different rowset because it may fail

DECLARE @osversion NVARCHAR(256)
DECLARE @regvalue NVARCHAR(256)
DECLARE @regvalueint INT
DECLARE @myhive NVARCHAR(256)
DECLARE @mykey NVARCHAR(1000)
DECLARE @pos INT
DECLARE @osmajorversion INT
DECLARE @fWinVista BIT
SET @myhive = N'HKEY_LOCAL_MACHINE'
SET @mykey = N'Software\Microsoft\Windows NT\CurrentVersion'
--get windows info from registry
EXEC xp_instance_regread
	@rootkey = @myhive,
	@key = @mykey,
	@value_name = 'CurrentVersion',
	@value = @regvalue OUTPUT


SET @pos = CHARINDEX(N'.', @regvalue)
IF @pos != 0
BEGIN
	INSERT INTO #summary VALUES ('operating system version major',SUBSTRING(@regvalue, 1, @pos-1))
	INSERT INTO #summary VALUES ('operating system version minor',SUBSTRING(@regvalue, @pos+1, LEN(@regvalue)))

	SET @osmajorversion = SUBSTRING(@regvalue, 1, @pos-1)
	IF @osmajorversion >= 6
	BEGIN
		SET @fWinVista = 1
	END
	ELSE
	BEGIN
		SET @fWinVista = 0
	END
	
	EXEC xp_instance_regread
		@rootkey = @myhive,
		@key = @mykey,
		@value_name = 'CurrentBuildNumber',
		@value = @regvalue OUTPUT

	INSERT INTO #summary VALUES ('operating system version build', @regvalue)
	
	EXEC xp_instance_regread
		@rootkey = @myhive,
		@key = @mykey,
		@value_name = 'ProductName',
		@value = @osversion OUTPUT
	EXEC xp_instance_regread
		@rootkey = @myhive,
		@key = @mykey,
		@value_name = 'CSDVersion',
		@value = @regvalue OUTPUT

	INSERT INTO #summary VALUES ('operating system', @osversion + N' ' + @regvalue)

	EXEC xp_instance_regread
		@rootkey = @myhive,
		@key = @mykey,
		@value_name = 'InstallDate',
		@value = @regvalueint OUTPUT

	INSERT INTO #summary VALUES ('operating system install date', CONVERT(VARCHAR(23), DATEADD(SECOND, @regvalueint, '1970-01-01'), 121))

	/*
	other possible values of interest
	CurrentType
	InstallationType
	EditionID
	SoftwareType
	*/
END

IF @fWinVista = 1
BEGIN
	SET @mykey = N'SYSTEM\CurrentControlSet\Control\SystemInformation'
	--get system info from registry
	EXEC xp_instance_regread
		@rootkey = @myhive,
		@key = @mykey,
		@value_name = 'SystemManufacturer',
		@value = @regvalue OUTPUT
	INSERT INTO #summary VALUES ('registry SystemManufacturer', @regvalue)
	EXEC xp_instance_regread
		@rootkey = @myhive,
		@key = @mykey,
		@value_name = 'SystemProductName',
		@value = @regvalue OUTPUT
	INSERT INTO #summary VALUES ('registry SystemProductName', @regvalue)	

	--get powerplan from registry
	SET @mykey = N'SYSTEM\CurrentControlSet\Control\Power\User\Default\PowerSchemes'

	EXEC   xp_instance_regread
		@rootkey = @myhive,
		@key = @mykey,
		@value_name = 'ActivePowerScheme',
		@value = @regvalue OUTPUT

	SET @mykey = @mykey + N'\' + @regvalue

	EXEC   xp_instance_regread
		@rootkey = @myhive,
		@key = @mykey,
		@value_name = 'FriendlyName',
		@value = @regvalue OUTPUT

	DECLARE @string NVARCHAR(100)
	SET @string = N'@%SystemRoot%\system32\powrprof.dll,'
	SET @pos = CHARINDEX(@string, @regvalue)
	IF @pos != 0
	BEGIN
		DECLARE @len int
		SET @len = LEN(@string)+1
		SET @pos = CHARINDEX(N',', @regvalue, @len)
		IF @pos != 0
		BEGIN
			SET @regvalue = SUBSTRING(@regvalue, @pos+1, LEN(@regvalue))
		END
	END

	INSERT INTO #summary VALUES ('registry ActivePowerScheme (default)', @regvalue)	

	SET @mykey = N'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes'

	EXEC   xp_instance_regread
		@rootkey = 'HKEY_LOCAL_MACHINE',
		@key = @mykey,
		@value_name = 'ActivePowerScheme',
		@value = @regvalue OUTPUT

	SET @mykey = @mykey + N'\' + @regvalue

	EXEC   xp_instance_regread
		@rootkey = @myhive,
		@key = @mykey,
		@value_name = 'FriendlyName',
		@value = @regvalue OUTPUT

	INSERT INTO #summary VALUES ('registry ActivePowerScheme', @regvalue)	
END

IF (@@MICROSOFTVERSION >= 167773760) --10.0.1600
begin
	exec sp_executesql N'insert into #summary select ''sqlserver_start_time'', convert(varchar(23),sqlserver_start_time,121) from sys.dm_os_sys_info'
	exec sp_executesql N'insert into #summary select ''resource governor enabled'', is_enabled from sys.resource_governor_configuration'
	insert into #summary values ('FilestreamShareName', cast (SERVERPROPERTY('FilestreamShareName') as nvarchar(max)))
	insert into #summary values ('FilestreamConfiguredLevel', cast (SERVERPROPERTY('FilestreamConfiguredLevel') as nvarchar(max)))
	insert into #summary values ('FilestreamEffectiveLevel', cast (SERVERPROPERTY('FilestreamEffectiveLevel') as nvarchar(max)))
	insert into #summary select 'number of active extended event traces',count(*) as 'cnt' from sys.dm_xe_sessions
end

IF (@@MICROSOFTVERSION >= 171050560) --10.50.1600
begin
	exec sp_executesql N'insert into #summary select ''possibly running in virtual machine'', virtual_machine_type from sys.dm_os_sys_info'
end

IF (@@MICROSOFTVERSION >= 184551476) --11.0.2100
begin
	exec sp_executesql N'insert into #summary select ''physical_memory_kb'', physical_memory_kb from sys.dm_os_sys_info'
	insert into #summary values ('HadrManagerStatus', cast (SERVERPROPERTY('HadrManagerStatus') as nvarchar(max)))
	insert into #summary values ('IsHadrEnabled', cast (SERVERPROPERTY('IsHadrEnabled') as nvarchar(max)))	
end

IF (@@MICROSOFTVERSION >= 201328592) --12.0.2000
begin
	insert into #summary values ('IsLocalDB', cast (SERVERPROPERTY('IsLocalDB') as nvarchar(max)))
	insert into #summary values ('IsXTPSupported', cast (SERVERPROPERTY('IsXTPSupported') as nvarchar(max)))
end

RAISERROR ('', 0, 1) WITH NOWAIT
RAISERROR ('--ServerProperty--', 0, 1) WITH NOWAIT

select * from #summary
order by PropertyName
drop table #summary
go

declare @startup table (ArgsName nvarchar(10), ArgsValue nvarchar(max))
insert into @startup EXEC master..xp_instance_regenumvalues 'HKEY_LOCAL_MACHINE',   'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\Parameters'
print ''
RAISERROR ('--Startup Parameters--', 0, 1) WITH NOWAIT
select * from @startup
go

create table #traceflg (TraceFlag int, Status int, Global int, Session int)
insert into #traceflg exec ('dbcc tracestatus (-1)')
print ''
RAISERROR ('--traceflags--', 0, 1) WITH NOWAIT
select * from #traceflg
drop table #traceflg
go

print ''
RAISERROR ('--sys.dm_os_schedulers--', 0, 1) WITH NOWAIT
select * from sys.dm_os_schedulers
go

IF (@@MICROSOFTVERSION >= 167773760 --10.0.1600
	and @@MICROSOFTVERSION < 171048960) --10.50.0.0
begin
	print ''
	RAISERROR ('--sys.dm_os_nodes--', 0, 1) WITH NOWAIT
	exec sp_executesql N'select node_id, memory_object_address, memory_clerk_address, io_completion_worker_address, memory_node_id, cpu_affinity_mask, online_scheduler_count, idle_scheduler_count active_worker_count, avg_load_balance, timer_task_affinity_mask, permanent_task_affinity_mask, resource_monitor_state, node_state_desc from sys.dm_os_nodes'
end
go

IF (@@MICROSOFTVERSION >= 171048960) --10.50.0.0
begin
	print ''
	RAISERROR ('--sys.dm_os_nodes--', 0, 1) WITH NOWAIT
	exec sp_executesql N'select node_id, memory_object_address, memory_clerk_address, io_completion_worker_address, memory_node_id, cpu_affinity_mask, online_scheduler_count, idle_scheduler_count active_worker_count, avg_load_balance, timer_task_affinity_mask, permanent_task_affinity_mask, resource_monitor_state, online_scheduler_mask, processor_group, node_state_desc from sys.dm_os_nodes'
end
go

print ''
RAISERROR ('--dm_os_sys_info--', 0, 1) WITH NOWAIT
select * from sys.dm_os_sys_info
go

if cast (SERVERPROPERTY('IsClustered') as int) = 1
begin
	print ''
	RAISERROR ('--fn_virtualservernodes--', 0, 1) WITH NOWAIT
	SELECT * FROM fn_virtualservernodes()
end
go


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
go


print ''
RAISERROR ('--database files--', 0, 1) WITH NOWAIT
select database_id, [file_id], file_guid, [type],  LEFT(type_desc,10) as 'type_desc', data_space_id, [state], LEFT(state_desc,16) as 'state_desc', size, max_size, growth,
  is_media_read_only, is_read_only, is_sparse, is_percent_growth, is_name_reserved, create_lsn,  drop_lsn, read_only_lsn, read_write_lsn, differential_base_lsn, differential_base_guid,
  differential_base_time, redo_start_lsn, redo_start_fork_guid, redo_target_lsn, redo_target_fork_guid, backup_lsn, db_name(database_id) as 'Database_name',  name, physical_name 
from master.sys.master_files order by database_id, type, file_id
print ''

go

print ''
RAISERROR ('--sys.databases_ex--', 0, 1) WITH NOWAIT
select cast(DATABASEPROPERTYEX (name,'IsAutoCreateStatistics') as int) 'IsAutoCreateStatistics', cast( DATABASEPROPERTYEX (name,'IsAutoUpdateStatistics') as int) 'IsAutoUpdateStatistics', cast (DATABASEPROPERTYEX (name,'IsAutoCreateStatisticsIncremental') as int) 'IsAutoCreateStatisticsIncremental', *  from sys.databases
go

print ''
RAISERROR ('-- Windows Group Default Databases other than master --', 0, 1) WITH NOWAIT
select name,default_database_name from sys.server_principals where [type] = 'G' and is_disabled = 0 and default_database_name != 'master'
go

print ''
RAISERROR ('-- sys.database_mirroring --', 0, 1) WITH NOWAIT
IF (@@MICROSOFTVERSION >= 167772160) --10.0.0
begin
	exec sp_executesql N'select database_id, mirroring_guid, mirroring_state, mirroring_role, mirroring_role_sequence, mirroring_safety_level, mirroring_safety_sequence, 
			mirroring_witness_state, mirroring_failover_lsn, mirroring_end_of_log_lsn, mirroring_replication_lsn, mirroring_connection_timeout, mirroring_redo_queue,
			db_name(database_id) as ''database_name'', mirroring_partner_name, mirroring_partner_instance, mirroring_witness_name 
		from sys.database_mirroring where mirroring_guid IS NOT NULL'
end
else
begin
	select database_id, mirroring_guid, mirroring_state, mirroring_role, mirroring_role_sequence, mirroring_safety_level, mirroring_safety_sequence, 
			mirroring_witness_state, mirroring_failover_lsn, mirroring_connection_timeout, mirroring_redo_queue,
			db_name(database_id) as 'database_name', mirroring_partner_name, mirroring_partner_instance, mirroring_witness_name 
		from sys.database_mirroring where mirroring_guid IS NOT NULL
end
go

IF @@MICROSOFTVERSION >= 184551476 --11.0.2100
begin
  print ''
  RAISERROR ('--Hadron Configuration--', 0, 1) WITH NOWAIT
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
      --ar.secondary_role_allow_read_desc
  FROM 
      sys.availability_groups AS ag 
      JOIN sys.availability_replicas AS ar 
      ON ag.group_id = ar.group_id
      JOIN sys.dm_hadr_availability_replica_states AS ar_state 
      ON  ar.replica_id = ar_state.replica_id;

  print ''
  RAISERROR ('--sys.availability_groups--', 0, 1) WITH NOWAIT
  select * from sys.availability_groups


  print ''
  RAISERROR ('--sys.dm_hadr_availability_group_states--', 0, 1) WITH NOWAIT
  select * from sys.dm_hadr_availability_group_states

  print ''
  RAISERROR ('--sys.dm_hadr_availability_replica_states--', 0, 1) WITH NOWAIT
  select * from sys.dm_hadr_availability_replica_states

  print ''
  RAISERROR ('--sys.availability_replicas--', 0, 1) WITH NOWAIT
  select * from sys.availability_replicas

  print ''
  RAISERROR ('--sys.dm_hadr_database_replica_cluster_states--', 0, 1) WITH NOWAIT
  select * from sys.dm_hadr_database_replica_cluster_states

  print ''
  RAISERROR ('--sys.availability_group_listeners--', 0, 1) WITH NOWAIT
  select * from sys.availability_group_listeners

  print ''
  RAISERROR ('--sys.dm_hadr_cluster_members--', 0, 1) WITH NOWAIT
  select * from sys.dm_hadr_cluster_members
end
go

print '-- sys.change_tracking_databases --'
select * from sys.change_tracking_databases
print ''


print '-- sys.dm_database_encryption_keys --'
select database_id, encryption_state from sys.dm_database_encryption_keys
print ''

go

print '-- sys.dm_tran_persistent_version_store_stats --'
select * From sys.dm_tran_persistent_version_store_stats
print ''
go
/*
--windows version from @@version
declare @pos int
set @pos = CHARINDEX(N' on ',@@VERSION)
print substring(@@VERSION, @pos + 4, LEN(@@VERSION))
*/


print '--profiler trace summary--'
SELECT traceid, property, CONVERT (varchar(1024), value) AS value FROM :: fn_trace_getinfo(default)

go
--we need the space for import
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
