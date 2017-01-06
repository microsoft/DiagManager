-- PSSDIAG Replication Metadata Collector
-- jmneto May, 26, 2010
-- tzakir Jan  6, 2017 (Added AG table MSredirected_publishers) 

use tempdb
go

set nocount off
go

if (object_id('ReplPssdiagExecuteCommandOnDbType') IS NOT NULL)
	drop proc dbo.ReplPssdiagExecuteCommandOnDbType
go
  
create proc dbo.ReplPssdiagExecuteCommandOnDbType
	@DbType nchar(50) = 'TranPublisher',
	@Command nvarchar(4000) = null
	as

	declare	@ParsedCommand nvarchar(4000)
	declare @DbName sysname
	declare @Category int
	declare @objectName sysname

	set @Category = 1 -- Default or wrong parameter

	if (@DbType = 'TranPublisher')
		set @Category = 1

	if (@DbType = 'MergePublisher')
		set @Category = 4

	if (@DbType = 'MergeSubscriber') -- We don't have a category to identify any Subscriber
		set @Category = -1

	if (@DbType = 'TranSubscriber') -- We don't have a category to identify any Subscriber
		set @Category = -1

	if (@DbType = 'Distributor')
		set @Category = 16

	declare selectedDatabases cursor  
		for 
		select [name] from master.dbo.sysdatabases 
		where (category  & @Category) = @Category
		and (status & 0x03e0 = 0)
		and (DATABASEPROPERTY([name], 'issingleuser') = 0 
		and (has_dbaccess([name]) = 1))
		or (category = 0 and @Category = -1 )  -- Susbcribers are checked with object_id and known table, so get all dbs

	open  selectedDatabases
	fetch next from selectedDatabases into @DbName

	while @@FETCH_STATUS = 0
	begin
		if (@DbType = 'TranSubscriber')  -- Subscriber(tran)
		begin
			if (object_id( @DbName + '..MSreplication_objects') IS  NULL) -- This db is not really a tran subscriber so try next
			begin
				fetch next from selectedDatabases into @DbName
				continue
			end
		end
				
		if (@DbType = 'MergeSubscriber')  -- Subscriber(merge) 
		begin
			if (object_id( @DbName + '..MSmerge_Contents') IS  NULL) -- This db is not really a merge subscriber so try next
			begin
				fetch next from selectedDatabases into @DbName
				continue
			end
		end
						
		select @ParsedCommand = Replace(@Command,N'?',@DbName)

		print N'-> ' + @ParsedCommand
		begin try
			exec(@ParsedCommand )
		end try
		begin catch
			print N'Not able to execute above query'	
		end catch
		print ''
			
		fetch next from selectedDatabases into @DbName
	end

	close selectedDatabases
	deallocate selectedDatabases
go

use master;
go

print '-> Start Time'
select [getdate]=getdate()


-- Global Server Data
print '-> select [@@ServerName] = @@servername'
select [@@ServerName] = @@servername  
print '-> select [@@Version] = @@version'
select [@@Version] = @@version
go

-- Master
print '-> select * from [master].[dbo].[sysservers]'
select * from [master].[dbo].[sysservers]
go
print '-> select * from [master].[dbo].[sysdatabases]'
select * from [master].[dbo].[sysdatabases]
go

-- msdb
print '-> select * from [msdb].[dbo].[sysjobs]'
select * from [msdb].[dbo].[sysjobs]
go


-- Replication Specific Data - DistributionDb
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSpublications] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSarticles] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSlogreader_agents] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select top 1000 * from [?].[dbo].[MSlogreader_history] (nolock) order by time desc'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [distribution].[dbo].[MSsnapshot_agents] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select top 1000 * from [?].[dbo].[MSsnapshot_history] (nolock) order by time desc'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select *  from [?].[dbo].[MSdistribution_agents] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select top 1000 * from [?].[dbo].[MSdistribution_history] (nolock) order by  time desc'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSmerge_agents] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select top 1000 *  from [?].[dbo].[MSmerge_history] (nolock) order by time desc'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSqreader_agents] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select top 1000 * from [?].[dbo].[MSqreader_history] (nolock) order by start_time desc'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select top 1000 publisher_database_id,xact_seqno,count(*) as numcommands from [?].[dbo].[MSrepl_commands] (nolock) group by publisher_database_id,xact_seqno order by publisher_database_id,numcommands DESC'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select top 1000 * from [?].[dbo].[msrepl_errors] ORDER BY [TIME] DESC'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select error_code,[Count]=count(*) from [?].[dbo].[msrepl_errors] GROUP BY error_code '
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MScached_peer_lsns] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSrepl_backup_lsns] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSrepl_originators] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSrepl_version] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSmerge_articlehistory] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSmerge_history] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSmerge_identity_range_allocations] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSrepl_identity_range] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSmerge_sessions] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSmerge_subscriptions] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSpublication_access] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSpublications] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSpublicationthresholds] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSpublisher_databases] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSreplication_monitordata] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSsubscriber_info] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSsubscriber_schedule] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSsubscriptions] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSsync_states] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MStracer_history] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MStracer_tokens] (nolock)'
go

exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [?].[dbo].[MSredirected_publishers] (nolock)'
go



-- Transactional Publisher
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[syspublications] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[syssubscriptions] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[sysarticles] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select top 1000 * from [?].[dbo].[msrepl_errors] ORDER BY [TIME] DESC'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[sysreplservers] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[sysarticlecolumns] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[sysschemaarticles] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[sysarticleupdates] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[MSpub_identity_range] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[systranschemas] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[MSpeer_conflictdetectionconfigresponse] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[MSpeer_lsns] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[MSpeer_request] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[MSpeer_response] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[MSpeer_topologyrequest] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[MSpeer_topologyresponse] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[MSpeer_originatorid_history] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranPublisher','select * from [?].[dbo].[MSpeer_conflictdetectionconfigrequest] (nolock)'
go


-- Transactional Subscriber
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranSubscriber','select * from [?].[dbo].[MSreplication_subscriptions] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranSubscriber','select * from [?].[dbo].[MSsubscription_agents] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'TranSubscriber','select * from [?].[dbo].[MSreplication_objects] (nolock)'
go


-- Merge Publisher
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[sysmergearticles] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[sysmergepartitioninfo] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[sysmergepublications] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[sysmergeschemaarticles] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[sysmergeschemachange] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[sysmergesubscriptions] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[sysmergesubsetfilters] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_agent_parameters] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_altsyncpartners] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_articlehistory] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_conflicts_info] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_dynamic_snapshots] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSdynamicsnapshotviews] (nolock)'	
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSdynamicsnapshotjobs] (nolock)'	
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_errorlineage] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_history] (nolock) order by time desc'	
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_identity_range] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_log_files] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_metadataaction_request] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_replinfo] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_sessions] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_settingshistory] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_supportability_settings] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_generation_partition_mappings] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_partition_groups] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select top 1000 * from [?].[dbo].[msrepl_errors] ORDER BY [TIME] DESC'
go
-- Do not capture big tables
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_tombstone] (nolock)'		
--go
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_genhistory] (nolock)'	
--go
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_contents] (nolock)'		
--go
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_current_partition_mappings] (nolock)'
--go
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergePublisher','select * from [?].[dbo].[MSmerge_past_partition_mappings] (nolock)'
--go


-- Merge Subscriber
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[sysmergearticles] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[sysmergepartitioninfo] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[sysmergepublications] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[sysmergeschemaarticles] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[sysmergeschemachange] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from  [?].[dbo].[sysmergesubscriptions] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[sysmergesubsetfilters] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_agent_parameters] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_altsyncpartners] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_articlehistory] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_conflicts_info] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_dynamic_snapshots] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSsnapshotdeliveryprogress] (nolock)'	
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSdynamicsnapshotviews] (nolock)'	
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSdynamicsnapshotjobs] (nolock)'	
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_errorlineage] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_history] (nolock) order by time desc'	
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_identity_range] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_log_files] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_metadataaction_request] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_replinfo] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_sessions] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_settingshistory] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_supportability_settings] (nolock)'		
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_generation_partition_mappings] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_partition_groups] (nolock)'
go
exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select top 1000 * from [?].[dbo].[msrepl_errors] ORDER BY [TIME] DESC'
go
-- Do not capture big tables
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_tombstone] (nolock)'		
--go
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_contents] (nolock)'	
--go
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_genhistory] (nolock)'		
--go
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_current_partition_mappings] (nolock)'
--go
--exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'MergeSubscriber','select * from [?].[dbo].[MSmerge_past_partition_mappings] (nolock)'
--go



-- Clean up
use tempdb
go
if (object_id('ReplPssdiagExecuteCommandOnDbType') IS NOT NULL)
	drop proc dbo.ReplPssdiagExecuteCommandOnDbType
go



print '-> End Time'
select [getdate]=getdate()

