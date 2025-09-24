Go
SET NOCOUNT ON   
Go
SELECT GetDate()
Go

--Database Mirroring Endpoint Information
PRINT '==========================='
PRINT 'Database Mirroring Endpoint'
PRINT '==========================='
PRINT ''
select name=cast(name as varchar(30)),
endpoint_id, principal_id, 
protocol_desc=cast(protocol_desc as varchar(20)),
type_desc=cast(type_desc as varchar(30)),
state_desc=cast(state_desc as varchar(20)),
is_admin_endpoint,
role_desc=cast(role_desc as varchar(30)),
is_encryption_enabled,
connection_auth_desc=cast(connection_auth_desc as varchar(30)),
encryption_algorithm_desc=cast(encryption_algorithm_desc as varchar(20))
from sys.database_mirroring_endpoints

PRINT ''

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

PRINT ''

--Availability Group Listeners and IP
PRINT '==================================='
PRINT 'Availability Group Listeners and IP'
PRINT '==================================='
PRINT ''
select l.listener_id,
state_desc=cast(lia.state_desc as varchar(20)),
dns_name=cast(l.dns_name as varchar(30)),
 l.port, l.is_conformant,
ip_configuration_string_from_cluster=cast(l.ip_configuration_string_from_cluster as varchar(40)),
ip_address=cast(lia.ip_address as varchar(30)),
lia.ip_subnet_mask, lia.is_dhcp, 
network_subnet_ip=cast(lia.network_subnet_ip as varchar(30)),
lia.network_subnet_prefix_length,
network_subnet_ipv4_mask=cast(lia.network_subnet_ipv4_mask as varchar(30)),
lia.network_subnet_prefix_length
 from sys.availability_group_listeners l join
sys.availability_group_listener_ip_addresses lia
on l.listener_id=lia.listener_id

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
select  cluster_name=cast(c.cluster_name as char(30)), 
quorum_type=cast(c.quorum_type_desc as char(30)), 
quorum_state_desc=cast(c.quorum_state_desc as char(30))
from sys.dm_hadr_cluster c

PRINT ''

-- Implementing changes requested by CMathews as documented in bug 253897
-- Modified By Shonh using Cmathews new changes.. 
-- AlwaysOn Cluster Information
PRINT '================================================'
PRINT 'Windows Cluster Member State, Quorum and Network'
PRINT '================================================'
PRINT ''
select member_name=cast(cm.member_name as varchar(30)), 
member_type_desc=cast(cm.member_type_desc as varchar(30)), 
member_state_desc=cast(cm.member_state_desc as varchar(10)),
cm.number_of_quorum_votes,
cast(cn.network_subnet_ip as varchar(40)),
cast(cn.network_subnet_ipv4_mask as varchar(40)),
cn.network_subnet_prefix_length,
cn.is_public,
cn.is_ipv4
from sys.dm_hadr_cluster_members cm join sys.dm_hadr_cluster_networks cn
on cm.member_name=cn.member_name


PRINT ''

--AlwaysOn Availability Group State, Identification and Configuration
PRINT '==================================================================='
PRINT 'AlwaysOn Availability Group State, Identification and Configuration'
PRINT '==================================================================='
PRINT ''
select availability_group=cast(ag.name as varchar(30)), 
primary_replica=cast(ags.primary_replica as varchar(30)),
primary_recovery_health_desc=cast(ags.primary_recovery_health_desc as varchar(30)),
synchronization_health_desc=cast(ags.synchronization_health_desc as varchar(30)),
ag.group_id, ag.resource_id, ag.resource_group_id, ag.failure_condition_level, 
ag.health_check_timeout, 
automated_backup_preference_desc=cast(ag.automated_backup_preference_desc as varchar(10))
from sys.availability_groups ag join sys.dm_hadr_availability_group_states ags
on ag.group_id=ags.group_id

PRINT ''

--AlwaysOn Availability Replica State, Identification and Configuration
PRINT '====================================================================='
PRINT 'AlwaysOn Availability Replica State, Identification and Configuration'
PRINT '====================================================================='
PRINT ''
SELECT 
	group_name=cast(arc.group_name as varchar(30)), 
	replica_server_name=cast(arc.replica_server_name as varchar(30)), 
	node_name=cast(arc.node_name as varchar(30)),
	ars.is_local, 
	role_desc=cast(ars.role_desc as varchar(30)), 
	availability_mode=cast(ar.availability_mode as varchar(30)),
	ar.availability_mode_Desc,
	failover_mode_desc=cast(ar.failover_mode_desc as varchar(30)),
	join_state_desc=cast(arcs.join_state_desc as varchar(30)),
	operational_state_desc=cast(ars.operational_state_desc as varchar(30)), 
	connected_state_desc=cast(ars.connected_state_desc as varchar(30)), 
	recovery_health_desc=cast(ars.recovery_health_desc as varchar(30)), 
	synhcronization_health_desc=cast(ars.synchronization_health_desc as varchar(30)),
	ars.last_connect_error_number, 
	last_connect_error_description=cast(ars.last_connect_error_description as varchar(30)), 
	ars.last_connect_error_timestamp,
	endpoint_url=cast (ar.endpoint_url as varchar(30)),
	ar.session_timeout,
	primary_role_allow_connections_desc=cast(ar.primary_role_allow_connections_desc as varchar(30)),
	secondary_role_allow_connections_desc=cast(ar.secondary_role_allow_connections_desc as varchar(30)),
	ar.create_date,
	ar.modify_date,
	ar.backup_priority, 
	ar.read_only_routing_url,
	arcs.replica_id, 
	arcs.group_id
from sys.dm_hadr_availability_replica_cluster_nodes arc 
join sys.dm_hadr_availability_replica_cluster_states arcs on arc.replica_server_name=arcs.replica_server_name
join sys.dm_hadr_availability_replica_states ars on arcs.replica_id=ars.replica_id
join sys.availability_replicas ar on ars.replica_id=ar.replica_id
join sys.availability_groups ag 
on ag.group_id = arcs.group_id 
and ag.name = arc.group_name 
--dm_hadr_availability_replica_cluster_nodes doesn't have a group_id, so we have to join by name
ORDER BY 
cast(arc.group_name as varchar(30)), 
cast(ars.role_desc as varchar(30))

PRINT ''

--AlwaysOn Availability Database Identification, Configuration, State and Performance
PRINT '==================================================================================='
PRINT 'AlwaysOn Availability Database Identification, Configuration, State and Performance'
PRINT '==================================================================================='
PRINT ''
select 
database_name=cast(drcs.database_name as varchar(30)), 
drs.database_id,
drs.group_id,
drs.replica_id,
drs.is_local,
drcs.is_failover_ready,
drcs.is_pending_secondary_suspend,
drcs.is_database_joined,
drs.is_suspended,
drs.is_commit_participant,
suspend_reason_desc=cast(drs.suspend_reason_desc as varchar(30)),
synchronization_state_desc=cast(drs.synchronization_state_desc as varchar(30)),
synchronization_health_desc=cast(drs.synchronization_health_desc as varchar(30)),
database_state_desc=cast(drs.database_state_desc as varchar(30)),
drs.last_sent_lsn,
drs.last_sent_time,
drs.last_received_lsn,
drs.last_received_time,
drs.last_hardened_lsn,
drs.last_hardened_time,
drs.last_redone_lsn,
drs.last_redone_time,
drs.log_send_queue_size,
drs.log_send_rate,
drs.redo_queue_size,
drs.redo_rate,
drs.filestream_send_rate,
drs.end_of_log_lsn,
drs.last_commit_lsn,
drs.last_commit_time,
drs.low_water_mark_for_ghosts,
drs.recovery_lsn,
drs.truncation_lsn,
pr.file_id,
pr.error_type,
pr.page_id,
pr.page_status,
pr.modification_time
from sys.dm_hadr_database_replica_cluster_states drcs join 
sys.dm_hadr_database_replica_states drs on drcs.replica_id=drs.replica_id
and drcs.group_database_id=drs.group_database_id left outer join
sys.dm_hadr_auto_page_repair pr on drs.database_id=pr.database_id 
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
