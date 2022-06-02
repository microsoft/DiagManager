SET NOCOUNT ON
GO
SELECT GETDATE()
GO

-- Get the information about the endpoints, owners, config, etc.
PRINT '==========================='
PRINT 'Database Mirroring Endpoint'
PRINT '==========================='
PRINT ''

SELECT *
FROM sys.tcp_endpoints tcpe
	inner join sys.database_mirroring_endpoints me
		on tcpe.endpoint_id = me.endpoint_id
	inner join sys.server_principals sp
		on tcpe.principal_id = sp.principal_id

--Database Mirroring Endpoint Permissions
PRINT '======================================='
PRINT 'Database Mirroring Endpoint Permissions'
PRINT '======================================='
PRINT ''
SELECT cast(perm.class_desc as varchar(30)) as [ClassDesc], cast(prin.name as varchar(30)) [Principal],
cast(perm.permission_name as varchar(30)) as [Permission],
cast(perm.state_desc as varchar(30)) as [StateDesc],
cast(prin.type_desc as varchar(30)) as [PrincipalType],
prin.is_disabled 
FROM sys.server_permissions perm
LEFT JOIN sys.server_principals prin
	ON perm.grantee_principal_id = prin.principal_id
LEFT JOIN sys.tcp_endpoints tep 
	ON perm.major_id = tep.endpoint_id
WHERE perm.class_desc = 'ENDPOINT' AND
perm.permission_name = 'CONNECT' AND
tep.type = 4

print ''

--Database Mirroring States
PRINT '======================================='
PRINT 'Database Mirroring States'
PRINT '======================================='
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
PRINT ''

--Availability Group Listeners and IP
PRINT '==================================='
PRINT 'Availability Group Listeners and IP'
PRINT '==================================='
PRINT ''
--First the listeners, one line per listener instead of the previous multi-line per IP.
-- IPs will be broken out in the next query.
SELECT agl.dns_name AS [Listener_Name], ag.name AS [AG_Name]
		, agl.*
FROM sys.availability_group_listeners agl
	inner join sys.availability_groups ag
		on agl.group_id = ag.group_id

--IP information which isn't fully returned via the query above.
SELECT agl.dns_name AS [Listener_Name], aglip.*
FROM sys.availability_group_listener_ip_addresses aglip
	inner join sys.availability_group_listeners agl
		on aglip.listener_id = agl.listener_id

PRINT ''


--ROUTING LIST INFO
PRINT '==================================='
PRINT 'ROUTING LIST INFO'
PRINT '==================================='
PRINT ''
SELECT cast(ar.replica_server_name as varchar(30)) [When This Server is Primary], 
	rl.routing_priority [Priority], 
	cast(ar2.replica_server_name as varchar(30)) [Route to this Server],
	ar.secondary_role_allow_connections_desc [Connections Allowed],
	cast(ar2.read_only_routing_url as varchar(50)) as [Routing URL]
	FROM sys.availability_read_only_routing_lists rl
	  inner join sys.availability_replicas ar on rl.replica_id = ar.replica_id
	  inner join sys.availability_replicas ar2 on rl.read_only_replica_id = ar2.replica_id
	ORDER BY ar.replica_server_name, rl.routing_priority

PRINT ''

--AlwaysOn Cluster Information
PRINT '========================'
PRINT 'AlwaysOn Windows Cluster'
PRINT '========================'
PRINT ''
SELECT  *
FROM sys.dm_hadr_cluster

PRINT ''

-- AlwaysOn Cluster Information
-- Note that this information is not guaranteed to be 100% accurate or correct since Windows Server 2012+.
PRINT '================================================'
PRINT 'Windows Cluster Member State, Quorum and Network'
PRINT '================================================'
PRINT ''
SELECT *
FROM sys.dm_hadr_cluster_members cm
	inner join sys.dm_hadr_cluster_networks cn
		on cn.member_name = cm.member_name

PRINT ''

--AlwaysOn Availability Group State, Identification and Configuration
PRINT '==================================================================='
PRINT 'AlwaysOn Availability Group State, Identification and Configuration'
PRINT '==================================================================='
PRINT ''
SELECT *
FROM sys.availability_groups ag
	inner join sys.dm_hadr_availability_group_states ags
		on ag.group_id = ags.group_id

PRINT ''

--AlwaysOn Availability Replica State, Identification and Configuration
PRINT '====================================================================='
PRINT 'AlwaysOn Availability Replica State, Identification and Configuration'
PRINT '====================================================================='
PRINT ''
SELECT arc.*, ar.*, ars.*
from sys.dm_hadr_availability_replica_cluster_nodes arc 
join sys.dm_hadr_availability_replica_cluster_states arcs on arc.replica_server_name=arcs.replica_server_name
join sys.dm_hadr_availability_replica_states ars on arcs.replica_id=ars.replica_id
join sys.availability_replicas ar on ars.replica_id=ar.replica_id
join sys.availability_groups ag 
on ag.group_id = arcs.group_id 
and ag.name = arc.group_name 
ORDER BY 
cast(arc.group_name as varchar(30)), 
cast(ars.role_desc as varchar(30))

PRINT ''

--AlwaysOn Availability Database Identification, Configuration, State and Performance
PRINT '==================================================================================='
PRINT 'AlwaysOn Availability Database Identification, Configuration, State and Performance'
PRINT '==================================================================================='
PRINT ''
select ag.name [Availability_Group], *
from sys.dm_hadr_database_replica_cluster_states drcs join 
sys.dm_hadr_database_replica_states drs on drcs.replica_id=drs.replica_id
and drcs.group_database_id=drs.group_database_id left outer join
sys.dm_hadr_auto_page_repair pr on drs.database_id=pr.database_id
inner join sys.availability_groups ag
	on ag.group_id = drs.group_id
order by drs.database_id

PRINT ''
PRINT ''

PRINT '-> dm_os_server_diagnostics_log_configurations'
select * from sys.dm_os_server_diagnostics_log_configurations

SET QUOTED_IDENTIFIER ON

DECLARE @XELFile VARCHAR(256)
SELECT @XELFile = path + 'AlwaysOn_health*.xel' FROM sys.dm_os_server_diagnostics_log_configurations

--read the AOHealth*.xel files into the table
SELECT cast(event_data as XML) AS EventData
  INTO #AOHealth
  FROM sys.fn_xe_file_target_read_file(
  @XELFile, NULL, null, null);

PRINT ''
PRINT '==========================='
PRINT 'AlwaysOn_health DDL Events'
PRINT '==========================='
SELECT  EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,
	EventData.value('(event/data/text)[1]', 'varchar(10)') AS DDLAction,
	EventData.value('(event/data/text)[2]', 'varchar(10)') AS DDLPhase,
	EventData.value('(event/data/value)[5]', 'varchar(20)') AS AGName,
	CAST(REPLACE(REPLACE(EventData.value('(event/data/value)[3]',
		'varchar(max)'), CHAR(10), ''), CHAR(13), '') AS VARCHAR(60)) AS DDLStatement
	FROM #AOHealth
	WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'alwayson_ddl_executed'
		AND UPPER(EventData.value('(event/data/value)[3]', 'varchar(60)')) NOT LIKE '%FAILOVER%'
	ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime');

PRINT ''
PRINT '============================='
PRINT 'AlwaysOn_health DDL FAILOVERS'
PRINT '============================='
SELECT  EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,
	EventData.value('(event/data/text)[1]', 'varchar(10)') AS DDLAction,
	EventData.value('(event/data/text)[2]', 'varchar(10)') AS DDLPhase,
	EventData.value('(event/data/value)[5]', 'varchar(20)') AS AGName,
	CAST(REPLACE(REPLACE(EventData.value('(event/data/value)[3]',
		'varchar(max)'), CHAR(10), ''), CHAR(13), '') AS VARCHAR(60)) AS DDLStatement
	FROM #AOHealth
	WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'alwayson_ddl_executed'
		AND UPPER(EventData.value('(event/data/value)[3]', 'varchar(60)')) LIKE '%FAILOVER%'
	ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime');

PRINT ''
PRINT '=========================================='
PRINT 'AlwaysOn_health AR MGR State Change Events'
PRINT '=========================================='
SELECT CONVERT(char(25), EventData.value('(event/@timestamp)[1]', 'datetime'), 121) AS TimeStampUTC,
EventData.value('(event/data/text)[1]', 'varchar(30)') AS CurrentStateDesc
FROM #AOHealth
WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'availability_replica_manager_state_change'
ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime');

PRINT ''
PRINT '======================================'
PRINT 'AlwaysOn_health AR State Change Events'
PRINT '======================================'
SELECT EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,
EventData.value('(event/data/value)[4]', 'varchar(20)') AS AGName,
EventData.value('(event/data/text)[1]', 'varchar(30)') AS PrevStateDesc,
EventData.value('(event/data/text)[2]', 'varchar(30)') AS CurrentStateDesc
FROM #AOHealth
WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'availability_replica_state_change'
ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime');


PRINT ''
PRINT '======================================'
PRINT 'Lease Expiration Events'
PRINT '======================================'
SELECT  EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,
    EventData.value('(event/data/value)[2]', 'varchar(max)') AS AGName,
    EventData.value('(event/data/value)[1]', 'varchar(max)') AS AG_ID
    FROM #AOHealth
    WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'availability_group_lease_expired'
    ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime');


    
PRINT ''
PRINT '======================================'
PRINT 'Error events'
PRINT '======================================'
SELECT  EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,
    EventData.value('(event/data/value)[1]', 'int') AS ErrorNum,
    EventData.value('(event/data/value)[2]', 'int') AS Severity,
    EventData.value('(event/data/value)[3]', 'int') AS State,
    EventData.value('(event/data/value)[4]', 'varchar(max)') AS UserDefined,
    EventData.value('(event/data/text)[5]', 'varchar(max)') AS Category,
    EventData.value('(event/data/text)[6]', 'varchar(max)') AS DestinationLog,
    EventData.value('(event/data/value)[7]', 'varchar(max)') AS IsIntercepted,
    EventData.value('(event/data/value)[8]', 'varchar(max)') AS ErrMessage
	INTO #error_reported
    FROM #AOHealth
    WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'error_reported';

	--display results from "error_reported" event data
	WITH ErrorCTE (ErrorNum, ErrorCount, FirstDate, LastDate) AS (
	SELECT ErrorNum, Count(ErrorNum), min(TimeStampUTC), max(TimeStampUTC) As ErrorCount FROM #error_reported
	    GROUP BY ErrorNum) 
	SELECT CAST(ErrorNum as CHAR(10)) ErrorNum,
	    CAST(ErrorCount as CHAR(10)) ErrorCount,
	    CONVERT(CHAR(25), FirstDate,121) FirstDate,
	    CONVERT(CHAR(25), LastDate, 121) LastDate,
		CAST(CASE ErrorNum 
		WHEN 35202 THEN 'A connection for availability group ... has been successfully established...'
		WHEN 1480 THEN 'The %S_MSG database "%.*ls" is changing roles ... because the AG failed over ...'
		WHEN 35206 THEN 'A connection timeout has occurred on a previously established connection ...'
		WHEN 35201 THEN 'A connection timeout has occurred while attempting to establish a connection ...'
		WHEN 41050 THEN 'Waiting for local WSFC service to start.'
		WHEN 41051 THEN 'Local WSFC service started.'
		WHEN 41052 THEN 'Waiting for local WSFC node to start.'
		WHEN 41053 THEN 'Local WSFC node started.'
		WHEN 41054 THEN 'Waiting for local WSFC node to come online.'
		WHEN 41055 THEN 'Local WSFC node is online.'
		WHEN 41048 THEN 'Local WSFC service has become unavailable.'
		WHEN 41049 THEN 'Local WSFC node is no longer online.'
		ELSE m.text END AS VARCHAR(81)) [Abbreviated Message]
	     FROM
	    ErrorCTE ec LEFT JOIN sys.messages m on ec.ErrorNum = m.message_id
	    and m.language_id = 1033
	ORDER BY CAST(ErrorCount as INT) DESC;


DROP TABLE #AOHealth
DROP TABLE #error_reported
