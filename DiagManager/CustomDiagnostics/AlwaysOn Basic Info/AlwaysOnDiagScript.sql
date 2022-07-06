SET NOCOUNT ON
GO
SELECT GETDATE()
GO

-- Get the information about the endpoints, owners, config, etc.
PRINT ''
PRINT '-- AG_hadr_endpoints_principals --'

SELECT        tcpe.name, tcpe.endpoint_id, tcpe.principal_id, tcpe.protocol, tcpe.protocol_desc, 
              tcpe.type, tcpe.type_desc, tcpe.state, tcpe.state_desc, tcpe.is_admin_endpoint, 
			  tcpe.port, tcpe.is_dynamic_port, tcpe.ip_address, 
              me.role, me.role_desc, me.is_encryption_enabled, me.connection_auth, me.connection_auth_desc, me.certificate_id, me.encryption_algorithm, me.encryption_algorithm_desc,
			  sp.name AS principal_Name,sp.sid, sp.type AS principal_type, sp.type_desc AS principal_type_desc,
			  sp.is_disabled, sp.create_date, sp.modify_date,sp.default_database_name, sp.default_language_name, sp.credential_id, sp.owning_principal_id, sp.is_fixed_role
FROM         sys.tcp_endpoints                AS tcpe 
INNER JOIN   sys.database_mirroring_endpoints AS me   ON tcpe.endpoint_id  = me.endpoint_id 
INNER JOIN   sys.server_principals            AS sp   ON tcpe.principal_id = sp.principal_id
OPTION (max_grant_percent = 3, MAXDOP 1)

--Database Mirroring Endpoint Permissions
PRINT ''
PRINT '-- AG_mirroring_endpoints_permissions --'
SELECT cast(perm.class_desc as varchar(30)) as [ClassDesc], 
       cast(prin.name as varchar(30)) [Principal],
       cast(perm.permission_name as varchar(30)) as [Permission], 
	   cast(perm.state_desc as varchar(30)) as [StateDesc],
       cast(prin.type_desc as varchar(30)) as [PrincipalType],
	   prin.is_disabled 
    FROM sys.server_permissions perm
LEFT JOIN sys.server_principals prin 	ON perm.grantee_principal_id = prin.principal_id
LEFT JOIN sys.tcp_endpoints     tep 	ON perm.major_id = tep.endpoint_id
WHERE perm.class_desc = 'ENDPOINT' AND perm.permission_name = 'CONNECT' AND tep.type = 4
OPTION (max_grant_percent = 3, MAXDOP 1)

--Database Mirroring States
PRINT ''
PRINT '-- AG_mirroring_states --'
SELECT database_id, mirroring_guid, mirroring_state, mirroring_role, mirroring_role_sequence, mirroring_safety_level, mirroring_safety_sequence, 
			mirroring_witness_state, mirroring_failover_lsn, mirroring_end_of_log_lsn, mirroring_replication_lsn, mirroring_connection_timeout, mirroring_redo_queue,
			db_name(database_id) as 'database_name', mirroring_partner_name, mirroring_partner_instance, mirroring_witness_name 
FROM sys.database_mirroring where mirroring_guid IS NOT NULL
OPTION (max_grant_percent = 3, MAXDOP 1)


--Availability Group Listeners and IP
--First the listeners, one line per listener instead of the previous multi-line per IP.
--IPs will be broken out in the next query.
PRINT ''
PRINT '-- AG_hadr_ag_listeners --'
DECLARE @sql_major_version INT, @sql_major_build INT, @sql NVARCHAR(max)

SELECT @sql_major_version = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 4) AS INT)),
       @sql_major_build = (CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 2) AS INT)) 
       

SET @sql ='SELECT agl.dns_name AS [Listener_Name], ag.name AS [AG_Name] ,agl.group_id,agl.listener_id,agl.dns_name,agl.port,agl.is_conformant,agl.ip_configuration_string_from_cluster'

IF ((@sql_major_version >=16) OR (@sql_major_version =15 AND @sql_major_build >=4073) OR (@sql_major_version =14 AND @sql_major_build >=3401) OR (@sql_major_version =13 AND @sql_major_build >=6300)) -- this exists  SQL 2019 CU8 ,SQL 2017 CU25,SQL 2016 SP3 and above
	BEGIN
	  SET @sql = @sql + ',agl.is_distributed_network_name'
	END
SET @sql = @sql + ' FROM sys.availability_group_listeners agl
INNER JOIN sys.availability_groups          ag ON agl.group_id = ag.group_id 
OPTION (max_grant_percent = 3, MAXDOP 1) '

EXEC(@sql)

SET @sql = ''

--IP information which isn't fully returned via the query above.
PRINT ''
PRINT '-- AG_hadr_ag_ip_information --'
SELECT        agl.dns_name AS Listener_Name, aglip.listener_id, aglip.ip_address, aglip.ip_subnet_mask, aglip.is_dhcp, aglip.network_subnet_ip, 
              aglip.network_subnet_prefix_length, aglip.network_subnet_ipv4_mask, aglip.state, aglip.state_desc
      FROM	sys.availability_group_listener_ip_addresses AS aglip 
INNER JOIN	sys.availability_group_listeners             AS agl	   ON aglip.listener_id = agl.listener_id
OPTION (max_grant_percent = 3, MAXDOP 1)


--ROUTING LIST INFO
PRINT ''
PRINT '-- AG_hadr_readonly_routing --'
SELECT	cast(ar.replica_server_name as varchar(30)) [WhenThisServerIsPrimary], 
   		rl.routing_priority [Priority], 
		cast(ar2.replica_server_name as varchar(30)) [RouteToThisServer],
		ar.secondary_role_allow_connections_desc [ConnectionsAllowed],
		cast(ar2.read_only_routing_url as varchar(50)) as [RoutingURL]

      FROM sys.availability_read_only_routing_lists rl
INNER JOIN sys.availability_replicas                ar  ON rl.replica_id = ar.replica_id
INNER JOIN sys.availability_replicas                ar2 ON rl.read_only_replica_id = ar2.replica_id
ORDER BY ar.replica_server_name, rl.routing_priority
OPTION (max_grant_percent = 3, MAXDOP 1)


--AlwaysOn Cluster Information
PRINT ''
PRINT '-- AG_hadr_cluster --'
SELECT  cluster_name,quorum_type,quorum_type_desc,quorum_state,quorum_state_desc
FROM sys.dm_hadr_cluster
OPTION (max_grant_percent = 3, MAXDOP 1)



-- AlwaysOn Cluster Information
-- Note that this information is not guaranteed to be 100% accurate or correct since Windows Server 2012+.
PRINT ''
PRINT '-- AG_hadr_cluster_members --'
SELECT        cm.member_name, cm.member_type, cm.member_type_desc, cm.member_state, cm.member_state_desc, cm.number_of_quorum_votes,
              cn.network_subnet_ip, cn.network_subnet_ipv4_mask, cn.network_subnet_prefix_length, cn.is_public, cn.is_ipv4
      FROM	sys.dm_hadr_cluster_members  AS cm 
INNER JOIN	sys.dm_hadr_cluster_networks AS cn ON cn.member_name = cm.member_name
OPTION (max_grant_percent = 3, MAXDOP 1)

PRINT ''

--AlwaysOn Availability Group State, Identification and Configuration 
SET @sql ='SELECT	 ag.group_id, ag.name, ag.resource_id, ag.resource_group_id, ag.failure_condition_level, ag.health_check_timeout, ag.automated_backup_preference,ag.automated_backup_preference_desc'

IF (@sql_major_version >=13) --these exists SQL 2016 and above
	BEGIN
	  SET @sql = @sql + ', ag.version, ag.basic_features ,ag.dtc_support, ag.db_failover, ag.is_distributed'
	END
IF (@sql_major_version >=14) --these exists SQL 2017 and above
	BEGIN
	  SET @sql = @sql + ', ag.cluster_type, ag.cluster_type_desc,ag.required_synchronized_secondaries_to_commit, ag.sequence_number'
	END
IF (@sql_major_version >=15) --this exists SQL 2019 and above
	BEGIN
	  SET @sql = @sql + ', ag.is_contained'
	END
SET @sql = @sql + ', ags.primary_replica, ags.primary_recovery_health, ags.primary_recovery_health_desc, ags.secondary_recovery_health,
		 ags.secondary_recovery_health_desc, ags.synchronization_health, ags.synchronization_health_desc
	  FROM	sys.availability_groups AS ag 
INNER JOIN	sys.dm_hadr_availability_group_states AS ags ON ag.group_id = ags.group_id 
OPTION (max_grant_percent = 3, MAXDOP 1)'
PRINT '-- AG_hadr_ag_states --'
EXEC(@sql)

SET @sql = ''


--AlwaysOn Availability Replica State, Identification and Configuration 
SET @sql ='SELECT        arc.group_name, arc.replica_server_name, arc.node_name, ar.replica_id, ar.group_id, ar.replica_metadata_id, 
              ar.owner_sid, ar.endpoint_url, ar.availability_mode, ar.availability_mode_desc, ar.failover_mode, ar.failover_mode_desc, 
			  ar.session_timeout, ar.primary_role_allow_connections, ar.primary_role_allow_connections_desc, ar.secondary_role_allow_connections, 
			  ar.secondary_role_allow_connections_desc, ar.create_date, ar.modify_date, ar.backup_priority, ar.read_only_routing_url '
IF (@sql_major_version >=13) --this exists SQL 2016 and above
	BEGIN
	  SET @sql = @sql + ', ar.seeding_mode, ar.seeding_mode_desc '
	END

IF (@sql_major_version >=15) --this exists SQL 2019 and above
	BEGIN
	  SET @sql = @sql + ', ar.read_write_routing_url'
	END

SET @sql = @sql + ' , ars.is_local, ars.role
					, role_desc = CASE WHEN ars.role_desc IS NULL THEN N''<unknown>'' ELSE ars.role_desc END
					, ars.operational_state
					, operational_state_desc = CASE WHEN ars.operational_state_desc  IS NULL THEN N''<unknown>'' ELSE ars.operational_state_desc END
					, ars.connected_state
					, connected_state_desc =  CASE WHEN ars.connected_state_desc IS NULL THEN CASE WHEN ars.is_local = 1 THEN N''CONNECTED'' ELSE N''<unknown>'' END ELSE ars.connected_state_desc END
					, ars.recovery_health, ars.recovery_health_desc, 
			  ars.synchronization_health, ars.synchronization_health_desc, ars.last_connect_error_number, ars.last_connect_error_description, 
			  ars.last_connect_error_timestamp '

IF (@sql_major_version >=14) --this exists SQL 2017 and above
	BEGIN
	  SET @sql = @sql + ', ars.write_lease_remaining_ticks'
	END
IF (@sql_major_version >=15) --this exists SQL 2019 and above
	BEGIN
	  SET @sql = @sql + ', ars.current_configuration_commit_start_time_utc'
	END
SET @sql = @sql + ' FROM	sys.dm_hadr_availability_replica_cluster_nodes  AS arc 
INNER JOIN  sys.dm_hadr_availability_replica_cluster_states AS arcs ON arc.replica_server_name = arcs.replica_server_name 
INNER JOIN	sys.dm_hadr_availability_replica_states         AS ars  ON arcs.replica_id = ars.replica_id 
INNER JOIN	sys.availability_replicas                       AS ar   ON ars.replica_id  = ar.replica_id 
INNER JOIN	sys.availability_groups                         AS ag   ON ag.group_id     = arcs.group_id AND ag.name = arc.group_name
ORDER BY CAST(arc.group_name AS varchar(30)), CAST(ars.role_desc AS varchar(30)) 
OPTION (max_grant_percent = 3, MAXDOP 1)'
PRINT ''
PRINT '-- AG_hadr_ag_replica_states --'
EXEC(@sql)

SET @sql = ''



--AlwaysOn Availability Database Identification, Configuration, State and Performance 
SET @sql ='SELECT  ag.name AS Availability_Group, drcs.replica_id, drcs.group_database_id, drcs.database_name, drcs.is_failover_ready, drcs.is_pending_secondary_suspend, 
        drcs.is_database_joined, drcs.recovery_lsn, drcs.truncation_lsn, drs.database_id, drs.group_id, drs.is_local '

IF (@sql_major_version >=12) --this exists SQL 2014 and above
	BEGIN
	  SET @sql = @sql + ', 	drs.is_primary_replica'
	END
SET @sql = @sql + ',  drs.synchronization_state, 
		drs.synchronization_state_desc, drs.is_commit_participant,drs.synchronization_health, drs.synchronization_health_desc, drs.database_state, drs.database_state_desc,
		drs.is_suspended, drs.suspend_reason, drs.suspend_reason_desc, drs.last_sent_lsn, drs.last_sent_time,
		drs.last_received_lsn, drs.last_received_time, drs.last_hardened_lsn, drs.last_hardened_time, drs.last_redone_lsn, drs.last_redone_time, 
        drs.log_send_queue_size, drs.log_send_rate, drs.redo_queue_size, drs.redo_rate, drs.filestream_send_rate, drs.end_of_log_lsn, drs.last_commit_lsn, drs.last_commit_time   '

IF (@sql_major_version >=12) --this exists SQL 2014 and above
	BEGIN
	  SET @sql = @sql + ', 	drs.low_water_mark_for_ghosts'
	END
IF (@sql_major_version >=13) --this exists SQL 2016 and above
	BEGIN
	  SET @sql = @sql + ', drs.secondary_lag_seconds'
	END
IF (@sql_major_version >=15) --this exists SQL 2019 and above
	BEGIN
	  SET @sql = @sql + ', drs.quorum_commit_lsn, drs.quorum_commit_time'
	END

SET @sql = @sql + ', pr.file_id, pr.page_id, pr.error_type, pr.page_status, pr.modification_time ,ag.name, ag.resource_id, ag.resource_group_id, ag.failure_condition_level, ag.health_check_timeout, ag.automated_backup_preference, ag.automated_backup_preference_desc'

IF (@sql_major_version >=13) --this exists SQL 2016 and above
	BEGIN
	  SET @sql = @sql + ', ag.version, ag.basic_features, ag.dtc_support, ag.db_failover, ag.is_distributed'
	END
IF (@sql_major_version >=14) --this exists SQL 2017 and above
	BEGIN
	  SET @sql = @sql + ', ag.cluster_type, ag.cluster_type_desc, ag.required_synchronized_secondaries_to_commit, ag.sequence_number'
	END
IF (@sql_major_version >=15) --this exists SQL 2019 and above
	BEGIN
	  SET @sql = @sql + ', ag.is_contained'
	END
SET @sql = @sql + ' FROM	sys.dm_hadr_database_replica_cluster_states AS drcs 
     INNER JOIN	sys.dm_hadr_database_replica_states         AS drs ON drcs.replica_id = drs.replica_id AND drcs.group_database_id = drs.group_database_id 
LEFT OUTER JOIN sys.dm_hadr_auto_page_repair                AS pr  ON drs.database_id = pr.database_id 
	 INNER JOIN	sys.availability_groups			            AS ag  ON ag.group_id     = drs.group_id
ORDER BY drs.database_id 
OPTION (max_grant_percent = 3, MAXDOP 1)'
PRINT ''
PRINT '--AG_hadr_ag_database_replica_states--'
EXEC(@sql)

SET @sql = ''
		 
PRINT ''
PRINT '-- AG_dm_os_server_diagnostics_log_configurations --'
SELECT        is_enabled, path, max_size, max_files
FROM            sys.dm_os_server_diagnostics_log_configurations

SET QUOTED_IDENTIFIER ON

DECLARE @XELFile VARCHAR(256)
SELECT @XELFile = path + 'AlwaysOn_health*.xel' FROM sys.dm_os_server_diagnostics_log_configurations

--read the AOHealth*.xel files into the table
SELECT cast(event_data as XML) AS EventData
  INTO #AOHealth
  FROM sys.fn_xe_file_target_read_file(
  @XELFile, NULL, null, null);

PRINT ''
PRINT '-- AG_AlwaysOn_health_alwayson_ddl_executed --'
SELECT TOP 500 
EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,
EventData.value('(event/data[@name="ddl_action"]/text)[1]', 'varchar(10)') AS DDLAction,
EventData.value('(event/data[@name="ddl_phase"]/text)[1]', 'varchar(10)') AS DDLPhase,
EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(20)') AS AGName,
CAST(REPLACE(REPLACE(EventData.value('(event/data[@name="statement"]/value)[1]','varchar(max)'), CHAR(10), ''), CHAR(13), '') AS VARCHAR(256)) AS DDLStatement
FROM #AOHealth
WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'alwayson_ddl_executed'
	AND UPPER(EventData.value('(event/data[@name="statement"]/value)[1]','varchar(max)')) NOT LIKE '%FAILOVER%'
ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime') DESC;

PRINT ''
PRINT '-- AG_AlwaysOn_health_failovers --'
SELECT TOP 500 
EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,
EventData.value('(event/data[@name="ddl_action"]/text)[1]', 'varchar(10)') AS DDLAction,
EventData.value('(event/data[@name="ddl_phase"]/text)[1]', 'varchar(10)') AS DDLPhase,
EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(20)') AS AGName,
CAST(REPLACE(REPLACE(EventData.value('(event/data[@name="statement"]/value)[1]','varchar(max)'), CHAR(10), ''), CHAR(13), '') AS VARCHAR(256)) AS DDLStatement
FROM #AOHealth
WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'alwayson_ddl_executed'
	AND UPPER(EventData.value('(event/data[@name="statement"]/value)[1]','varchar(max)')) LIKE '%FAILOVER%'
	AND UPPER(EventData.value('(event/data[@name="statement"]/value)[1]','varchar(max)')) NOT LIKE 'CREATE%' -- filter out AG Create
ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime') DESC
OPTION (max_grant_percent = 3, MAXDOP 1);

PRINT ''
PRINT '-- AG_AlwaysOn_health_availability_replica_manager_state_change --'
SELECT TOP 500 
CONVERT(char(25), EventData.value('(event/@timestamp)[1]', 'datetime'), 121) AS TimeStampUTC,
EventData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(30)') AS CurrentStateDesc
FROM #AOHealth
WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'availability_replica_manager_state_change'
ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime') DESC
OPTION (max_grant_percent = 3, MAXDOP 1);

PRINT ''
PRINT '-- AG_AlwaysOn_health_availability_replica_state_change --'
SELECT TOP 500 
EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,
EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(20)') AS AGName,
EventData.value('(event/data[@name="previous_state"]/text)[1]', 'varchar(30)') AS PrevStateDesc,
EventData.value('(event/data[@name="current_state"]/text)[1]', 'varchar(30)') AS CurrentStateDesc
FROM #AOHealth
WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'availability_replica_state_change'
ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime') DESC
OPTION (max_grant_percent = 3, MAXDOP 1);


PRINT ''
PRINT '-- AG_AlwaysOn_health_availability_group_lease_expired --'
SELECT  TOP 500 
EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,    
EventData.value('(event/data[@name="availability_group_name"]/value)[1]', 'varchar(20)') AS AGName,
EventData.value('(event/data[@name="availability_group_id"]/value)[1]', 'varchar(100)') AS AG_ID
FROM #AOHealth
WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'availability_group_lease_expired'
ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime') DESC
OPTION (max_grant_percent = 3, MAXDOP 1);


SELECT  TOP 500 
EventData.value('(event/@timestamp)[1]', 'datetime') AS TimeStampUTC,
EventData.value('(event/data[@name="error_number"]/value)[1]', 'int') AS ErrorNum,
EventData.value('(event/data[@name="severity"]/value)[1]', 'int') AS Severity,
EventData.value('(event/data[@name="state"]/value)[1]', 'int') AS State,
EventData.value('(event/data[@name="user_defined"]/value)[1]', 'varchar(max)') AS UserDefined,
EventData.value('(event/data[@name="category"]/text)[1]', 'varchar(max)') AS Category,
EventData.value('(event/data[@name="destination"]/text)[1]', 'varchar(max)') AS DestinationLog,
EventData.value('(event/data[@name="is_intercepted"]/value)[1]', 'varchar(max)') AS IsIntercepted,
EventData.value('(event/data[@name="message"]/value)[1]', 'varchar(max)') AS ErrMessage
INTO #error_reported
FROM #AOHealth
WHERE EventData.value('(event/@name)[1]', 'varchar(max)') = 'error_reported'
ORDER BY EventData.value('(event/@timestamp)[1]', 'datetime') DESC
OPTION (max_grant_percent = 3, MAXDOP 1);

	--display results from "error_reported" event data
PRINT ''
PRINT '-- AG_AlwaysOn_health_error_reported --';	
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
	ORDER BY CAST(ErrorCount as INT) DESC
	OPTION (max_grant_percent = 3, MAXDOP 1);


DROP TABLE #AOHealth
DROP TABLE #error_reported
