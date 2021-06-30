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


-- PerfStat script begin 
-- ***************************************************************************
-- copyright (c) microsoft corporation.
-- all rights reserved
--
-- @file: perfstat.sql
--
-- purpose: this script is to troubleshoot replication performance issue for css engineers to save their time.
--  
-- date:  02/15/2018
--
-- @endheader@
--
-- ***************************************************************************
set quoted_identifier on
set ansi_nulls on 
set nocount on
set implicit_transactions off
set ansi_warnings off
go



use tempdb
go

if object_id(N'proc_perfstat_distdb_backup', 'p') is not null
    drop procedure proc_perfstat_distdb_backup
go

if object_id(N'proc_distdb_validate', 'p') is not null
    drop procedure proc_distdb_validate
go

if object_id(N'proc_perfstat_env_set_up', 'p') is not null
    drop procedure proc_perfstat_env_set_up
go

if object_id(N'proc_perfstat_data_process', 'p') is not null
    drop procedure proc_perfstat_data_process
go

if object_id(N'proc_perfstat_transfer_xml_data_to_table', 'p') is not null
    drop procedure proc_perfstat_transfer_xml_data_to_table
go

if object_id(N'proc_perfstat_diagnose', 'p') is not null
    drop procedure proc_perfstat_diagnose
go

if object_id(N'proc_perfstat', 'p') is not null
    drop procedure proc_perfstat
go


raiserror('creating procedure proc_perfstat_distdb_backup', 0,1) with nowait
go
--
-- name: proc_perfstat_distdb_backup
--
-- description: this procedure is to back up the data of a distribution database along with the servers info (master.sys.servers) 
-- for performance trouble shooting, .bak file will be put under c driver.
-- 
-- parameters:	@distribution_db : name of the distribution database, the default is distribution
--
-- returns: 0 - succeed
--          1 - failed
--
-- security: this is a public interface object.
--
create procedure proc_perfstat_distdb_backup
(
@distribution_db sysname = 'distribution'
)
as
begin
	set nocount on

	--	the back up file name would be pf_backup_<distribution name>
	declare @db_backup_name nvarchar(128)
	set @db_backup_name = 'pf_backup_' + @distribution_db

	--  distribution server is not configured
	if object_id('msdb.dbo.MSdistributiondbs', 'u') is null
	begin
		raiserror (14071, 16, -1)
		return(1)
	end

	--	input distribution database is not valid.
	if @distribution_db not in (select name from msdb.dbo.MSdistributiondbs)
	begin
		raiserror (14117, 16, -1, @distribution_db)
		return(1)
	end

	-- create database for back up 
	exec('create database ' + @db_backup_name)

	-- get all needed info from distribution database
	exec('select *  into ' + @db_backup_name + '..MSarticles from ' + @distribution_db + '..MSarticles with (nolock)')
	exec('select *  into ' + @db_backup_name + '..MScached_peer_lsns from ' + @distribution_db + '..MScached_peer_lsns with (nolock)')
	exec('select *  into ' + @db_backup_name + '..MSdistribution_agents from ' + @distribution_db + '..MSdistribution_agents with (nolock)')
	exec('select *  into ' + @db_backup_name + '..MSdistribution_history from ' + @distribution_db + '..MSdistribution_history with (nolock)')
	exec('select *  into ' + @db_backup_name +'..MSlogreader_agents from ' + @distribution_db + '..MSlogreader_agents with (nolock)')
	exec('select *  into ' + @db_backup_name + '..MSlogreader_history from ' + @distribution_db + '..MSlogreader_history with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSmerge_agents from ' + @distribution_db + '..MSmerge_agents with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSmerge_articlehistory from ' + @distribution_db + '..MSmerge_articlehistory with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSmerge_history from ' + @distribution_db + '..MSmerge_history with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSmerge_identity_range_allocations from ' + @distribution_db + '..MSmerge_identity_range_allocations with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSmerge_sessions from ' + @distribution_db + '..MSmerge_sessions with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSmerge_subscriptions from ' + @distribution_db + '..MSmerge_subscriptions with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSpublication_access from ' + @distribution_db + '..MSpublication_access with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSpublications from ' + @distribution_db + '..MSpublications with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSpublicationthresholds from ' + @distribution_db + '..MSpublicationthresholds with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSpublisher_databases from ' + @distribution_db + '..MSpublisher_databases with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSqreader_agents from ' + @distribution_db + '..MSqreader_agents with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSqreader_history from ' + @distribution_db + '..MSqreader_history with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSrepl_backup_lsns from ' + @distribution_db + '..MSrepl_backup_lsns with (nolock)')
	exec('select top 100 * into '+ @db_backup_name +'..MSrepl_commands_OLDEST from ' + @distribution_db + '..MSrepl_commands with (nolock) order by xact_seqno asc')
	exec('select top 100 * into '+ @db_backup_name +'..MSrepl_commands_NEWEST from ' + @distribution_db + '..MSrepl_commands with (nolock) order by xact_seqno desc')
	exec('select *  into '+ @db_backup_name +'..MSrepl_errors from ' + @distribution_db + '..MSrepl_errors with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSrepl_identity_range from ' + @distribution_db + '..MSrepl_identity_range with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSrepl_originators from ' + @distribution_db + '..MSrepl_originators with (nolock)')
	exec('select top 100 * into '+ @db_backup_name +'..MSrepl_transactions_OLDEST from ' + @distribution_db + '..MSrepl_transactions with (nolock) order by xact_seqno asc')
	exec('select top 100 * into '+ @db_backup_name +'..MSrepl_transactions_NEWEST from ' + @distribution_db + '..MSrepl_transactions with (nolock) order by xact_seqno desc')
	exec('select *  into '+ @db_backup_name +'..MSrepl_version from ' + @distribution_db + '..MSrepl_version with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSreplication_monitordata from ' + @distribution_db + '..MSreplication_monitordata with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSsnapshot_agents from ' + @distribution_db + '..MSsnapshot_agents with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSsnapshot_history from ' + @distribution_db + '..MSsnapshot_history with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSsubscriber_info from ' + @distribution_db + '..MSsubscriber_info with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSsubscriber_schedule from ' + @distribution_db + '..MSsubscriber_schedule with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSsubscriptions from ' + @distribution_db + '..MSsubscriptions with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MSsync_states from ' + @distribution_db + '..MSsync_states with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MStracer_history from ' + @distribution_db + '..MStracer_history with (nolock)')
	exec('select *  into '+ @db_backup_name +'..MStracer_tokens from ' + @distribution_db + '..MStracer_tokens with (nolock)')
	

	-- get the server info (if now in distribution database AG then its MSreplservers under distribution database)
	if (object_id(@distribution_db + '..MSreplservers') is not null)
		exec('select * into '+ @db_backup_name +'..servers from ' + @distribution_db + '..MSreplservers with (nolock)')
	else
		exec('select * into '+ @db_backup_name +'..servers from master.sys.servers with (nolock)')

	-- back up the database and delete it after back up.
	exec('backup database '+ @db_backup_name +' to disk=''c:\' + @db_backup_name + '.bak''')
	exec('drop database ' + @db_backup_name)
	print('---------------location of back up file-------------------------')
	print('back up file generated : c:\' + @db_backup_name + '.bak')
	return (0)
end
go



raiserror('creating procedure proc_distdb_validate', 0,1) with nowait
go
--
-- name: proc_distdb_validate
--
-- description: this procedure is to validate that if there are enough meta data tables in back up database to support the troubleshooting.
-- 
-- parameters:	@distribution_db : name of the distribution database or database restored from back up of distribution db that we want to trouble shoot.
--
-- returns: 0 - validation succeed
--          1 - validation failed
--
-- security: this is a public interface object.
--
create procedure proc_distdb_validate
(
@distribution_db sysname
)
as
begin
	set nocount on
	-- for now, both history tables from logreader agent and distribution agent are required.
	if (OBJECT_ID(@distribution_db + N'..MSdistribution_history') is null )
	or 
	(OBJECT_ID(@distribution_db + N'..MSlogreader_history') is null )
	or
	(OBJECT_ID(@distribution_db + N'..MSlogreader_agents') is null )
	or
	(OBJECT_ID(@distribution_db + N'..MSdistribution_agents') is null )
	begin
		return (1)
	end
	return (0)
end
go


raiserror('creating procedure proc_perfstat_env_set_up', 0,1) with nowait
go
--
-- name: proc_perfstat_env_set_up
--
-- description: this procedure is to set up the resource info and tables for trouble shooting.
--				1) live mode (trouble shooting in the targeted distributor), by default we generate resource info tables for all available distribution databases in this distributor.
--				2) backup file trouble shooting mode, generate resource info tables based on the restored target database from back up file . 
-- 
-- parameters:	@distribution_db : name of the distribution database we want to trouble shoot.
--				@backup_troubleshooting : 0 for live mode trouble shooting, 1 for back up troubleshooting.
--
-- returns: 0 - succeed
--          1 - failed
--
-- security: this is a public interface object.
--
create procedure proc_perfstat_env_set_up
(
@distribution_data sysname = '%',
@backup_troubleshooting bit = 0
)
as
begin
	set nocount on 
	declare @retcode int
	declare @distdbname sysname
	declare @valid_dist_db bit = 0
	declare @query nvarchar(max)
	set @retcode = 0

	-- table distdbinfo stores the distribution database info we want to troubleshoot.
	if(object_id(N'tempdb.dbo.distdbinfo', 'u') is not null)
	begin
		drop table tempdb.dbo.distdbinfo
	end

	create table tempdb.dbo.distdbinfo(
		name sysname, 
		min_distretention int, 
		max_distretention int,
		history_retention int
	)
	
	--backup file trouble shooting mode
	if @backup_troubleshooting = 1
	begin
		-- store the distribution database info in table distdbinfo
		set @query  = 'insert into tempdb.dbo.distdbinfo (name) values ('+quotename(@distribution_data, '''')+')'
		exec(@query) 
		exec @valid_dist_db = proc_distdb_validate @distribution_data
		if @valid_dist_db = 1
		begin
			print concat(@distribution_data, ' doesnt have enough meta data to support troubleshooting.')
			return (1)
		end
	end
	--live mode
	else
	begin
		-- check if the sql server instance is configured as a distributor or not.
		if not exists (select * 
    					from master.dbo.sysservers
              			where upper(datasource collate database_default) = upper(@@servername) collate database_default
                 			and srvstatus & 8 <> 0)
		begin
			raiserror (14114, 16, -1, @@servername)
			return(1)      
		end
		--  could not find the distribution database for the local server. the distributor 
		--  may not be installed, or the local server may not be configured as a publisher at the distributor.
		if object_id('msdb.dbo.MSdistributiondbs', 'u') is null
		begin
			raiserror (14071, 16, -1)
			return(1)
		end   
		-- if no distribution database is available then return.
		if (select count(*) from msdb.dbo.MSdistributiondbs) <= 0
		begin
			return (0)
		end
		-- no distribution database specified then iterate all available distribution database.
		if @distribution_data = '%'
		begin
			insert into tempdb.dbo.distdbinfo select name, min_distretention, max_distretention,
				history_retention from msdb.dbo.MSdistributiondbs 
		end
		else
		begin
			-- input distribution database is not valid.
			if @distribution_data not in (select name from msdb.dbo.MSdistributiondbs)
			begin
				 raiserror (14117, 16, -1, @distribution_data)
				 return(1)
			end
			else
			begin
				-- store the distribution database info in table distdbinfo
				set @query  = 'insert into tempdb.dbo.distdbinfo select name, min_distretention, max_distretention,
				history_retention from msdb.dbo.MSdistributiondbs where name = ' + quotename(@distribution_data, '''')
				exec(@query)
			end
		end
	end
	-- table issuesdescription stores supported description items of delayed threads (reader or writer)
	if object_id('tempdb.dbo.issuesdescription', 'u') is null 
	begin
		create table tempdb.dbo.issuesdescription (
			issuedescription_id int primary key,
			agent_type nvarchar(50),
			delayed_thread nvarchar(25),
			[description] nvarchar(max)
		)

		insert into tempdb.dbo.issuesdescription values (
		1, 'logreader', 'reader', 
		'the reader thread is waiting for writer thread writing replication commands to the destination.'
		)
		insert into tempdb.dbo.issuesdescription values (
		2, 'logreader', 'writer', 
		'the writer tread is waiting for reader thread scanning the replicated changes from the transaction log.'
		)
		insert into tempdb.dbo.issuesdescription values (
		3, 'distribution', 'reader', 
		'the reader thread is waiting for writer thread applying replication commands against the subscriber server and database.'
		)
		insert into tempdb.dbo.issuesdescription values (
		4, 'distribution', 'writer', 
		'the writer thread is waiting for reader thread to supply buffers for the writer thread to apply at the subscriber database.'
		)
	end
	
	-- for every distribution database we want to trouble shoot, create 
	-- 1) replstatssourceinfo_<distribution_db_name> to store the collected statistics information from source tables,
	-- 2) distagentissues_<distribution_db_name> to store the results of distribution agent issues, 
	-- 3) logragentissues_<distribution_db_name> to store the results of log reader agent issues.
	declare cur cursor for select name from tempdb.dbo.distdbinfo
	open cur
	fetch next from cur into @distdbname
	while @@fetch_status = 0 
	begin
		declare @droptablecmd nvarchar(120)
		declare @replstatssourceinfo_tablename nvarchar(100)= 'tempdb.dbo.' + quotename(concat('replstatssourceinfo_', @distdbname))
		declare @logragentissues_tablename nvarchar(100) = 'tempdb.dbo.' + quotename(concat('logragentissues_', @distdbname))
		declare @distagentissues_tablename nvarchar(100) = 'tempdb.dbo.' + quotename(concat('distagentissues_', @distdbname))
		declare @logragentissues_tablename_replinfo nvarchar(100) = 'tempdb.dbo.' + quotename(concat('logragentissues_', @distdbname)) + '_replinfo'
		declare @distagentissues_tablename_replinfo nvarchar(100) = 'tempdb.dbo.' + quotename(concat('distagentissues_', @distdbname)) + '_replinfo'
		if object_id(@replstatssourceinfo_tablename, 'u') is not null
		begin
			set @droptablecmd = concat('drop table ', @replstatssourceinfo_tablename)
			exec(@droptablecmd)
		end

		if object_id(@logragentissues_tablename, 'u') is not null
		begin
			set @droptablecmd = concat('drop table ', @logragentissues_tablename)
			exec(@droptablecmd)
		end

		if object_id(@distagentissues_tablename, 'u') is not null
		begin
			set @droptablecmd = concat('drop table ', @distagentissues_tablename)
			exec(@droptablecmd)			
		end

		exec('create table ' + @replstatssourceinfo_tablename + '(
				id int not null identity primary key,
				time datetime,
				agent_id int,
				agent_name nvarchar(100),
				agent_type nvarchar(50),
				publisher_id smallint,
				publisher_name	nvarchar(128),
				publisher_db	nvarchar(128),
				subscriber_id	smallint,
				subscriber_name nvarchar(128),
				subscription_database	nvarchar(128),
				article_id	int,
				article_name	nvarchar(128),
				publication_id	int,
				publication_name	nvarchar(128),
				state	int,
				work	int,
				idle	int,
				cmds	int,
				callstogetreplcmds int,
				reader_fetch	int,
				reader_wait    	int,
				writer_write	int,
				writer_wait	int,
				sincelaststats_elaspsed_time	int,
				sincelaststats_work	int,
				sincelaststats_cmds	int,
				sincelaststats_cmspersec	[numeric](18, 0),
				sincelaststats_reader_fetch	int,
				sincelaststats_reader_wait	int,
				sincelaststats_writer_write	int,
				sincelaststats_writer_wait	int,
				comments nvarchar(max)
			)')

		exec ('create table ' + @logragentissues_tablename + '(
				agent_id	int,
				agent_name	nvarchar(100),
				state	int,
				cmds int,
				callstogetreplcmds int,
				reader_fetch	int,
				reader_wait    	int,
				writer_write	int,
				writer_wait	int,
				sincelaststats_work	int,
				sincelaststats_cmds	int,
				sincelaststats_cmspersec	[numeric](18, 0),
				sincelaststats_elaspsed_time	int,
				sincelaststats_reader_fetch	int,
				sincelaststats_reader_wait	int,
				sincelaststats_writer_write	int,
				sincelaststats_writer_wait	int,
				description	nvarchar(max),
				delayed_threads	nvarchar(100),
				time	datetime,
				comments nvarchar(max)
			)')
		
		exec('create table ' + @distagentissues_tablename + '(
			agent_id	int,
			agent_name	nvarchar(100),
			state	int,
			cmds int,
			callstogetreplcmds int,
			reader_fetch	int,
			reader_wait    	int,
			writer_write	int,
			writer_wait	int,
			sincelaststats_work	int,
			sincelaststats_elaspsed_time	int,
			sincelaststats_cmds	int,
			sincelaststats_cmspersec	[numeric](18, 0),
			sincelaststats_reader_fetch	int,
			sincelaststats_reader_wait	int,
			sincelaststats_writer_write	int,
			sincelaststats_writer_wait int,
			description	nvarchar(max),
			delayed_threads	nvarchar(100),
			time	datetime,
			comments nvarchar(max)		
			)')
		fetch next from cur into @distdbname
	end
	close cur    
	deallocate cur
end


raiserror('creating procedure proc_perfstat_transfer_xml_data_to_table', 0,1) with nowait
go
--
-- name: proc_perfstat_transfer_xml_data_to_table
--
-- description: this procedure is to transfer the xml statistics data in the replstatssourceinfo_<distribution_db_name>
--				into table format row by row via rowid.
-- 
-- parameters:	@stat_info_tablename nvarchar(50): name of target table replstatssourceinfo_<distribution_db_name> 
--				@xpath nvarchar(max): the xml statistics data
--				@rowid int: id of the row that we want to transfer the xml data into table format.
--				
-- security: this is a public interface object.
--
create procedure proc_perfstat_transfer_xml_data_to_table (
@replstattroubleshooting_tablename nvarchar(128),
@xpath nvarchar(max),
@rowid int
)
as
begin
	declare @xmldoc int
	declare @getstate varchar(1)
	declare @cmd nvarchar(max)
	exec sp_xml_preparedocument @xmldoc output, @xpath
	--print @xmldoc
	select @getstate = substring (@xpath, 15 , 1)

	-- xml format statistics with different state contains different info, so we need to transfer the 
	
	-- transfer the xml data of which the state marked as 1.
	if @getstate = '1'
	begin
		set @cmd = 'update ' + @replstattroubleshooting_tablename + ' set  
		[state] = tmp.[state],
		work = tmp.work,
		idle = tmp.idle,
		cmds = tmp.cmds,
		callstogetreplcmds = tmp.callstogetreplcmds,
		reader_fetch = tmp.[fetch], 
		reader_wait = tmp.fetch_wait,
		writer_write = tmp.write, 
		writer_wait = tmp.write_wait,
		sincelaststats_cmds = tmp.sincelaststats_cmds,
		sincelaststats_elaspsed_time = tmp.sincelaststats_elapsed_time,
		sincelaststats_work = tmp.sincelaststats_work,
		sincelaststats_cmspersec = tmp.sincelaststats_cmdspersec, 
		sincelaststats_reader_fetch = tmp.sincelaststats_fetch, 
		sincelaststats_reader_wait = tmp.sincelaststats_fetch_wait, 
		sincelaststats_writer_write = tmp.sincelaststats_write,
		sincelaststats_writer_wait = tmp.sincelaststats_write_wait
		from (select [state],work,idle,cmds,callstogetreplcmds,[fetch],fetch_wait,write, write_wait, sincelaststats_cmds, sincelaststats_elapsed_time,
		sincelaststats_work,  sincelaststats_cmdspersec, sincelaststats_fetch, sincelaststats_fetch_wait, sincelaststats_write,
		sincelaststats_write_wait from openxml ( @xmldoc, ''/'', 2)
		with (state int ''stats/@state'',
		work int ''stats/@work'',
		idle int ''stats/@idle'',
		cmds int ''stats/@cmds'',
		callstogetreplcmds int ''stats/@callstogetreplcmds'',
		[fetch] int ''stats/reader/@fetch'',
		fetch_wait int ''stats/reader/@wait'',
		write int ''stats/writer/@write'',
		write_wait int ''stats/writer/@wait'',
		sincelaststats_elapsed_time int ''stats/sincelaststats/@elapsedtime'',
		sincelaststats_work int ''stats/sincelaststats/@work'',
		sincelaststats_cmds int ''stats/sincelaststats/@cmds'',
		sincelaststats_cmdspersec decimal ''stats/sincelaststats/@cmdspersec'',
		sincelaststats_fetch int ''stats/sincelaststats/reader/@fetch'',
		sincelaststats_fetch_wait int ''stats/sincelaststats/reader/@wait'',
		sincelaststats_write int ''stats/sincelaststats/writer/@write'',
		sincelaststats_write_wait int ''stats/sincelaststats/writer/@wait'') ) tmp 
		where ' + @replstattroubleshooting_tablename + '.id = '+ convert(varchar, @rowid)

		exec sp_executesql @cmd, N'@xmldoc int', @xmldoc
	end

	-- transfer the xml data of which the state marked as 2.
	else if @getstate = '2'
	begin
		set @cmd = 'update ' + @replstattroubleshooting_tablename + ' set  
		[state] = tmp.[state], 
		cmds = tmp.cmds,
		callstogetreplcmds = tmp.callstogetreplcmds,
		reader_fetch = tmp.[fetch],  
		reader_wait = tmp.fetch_wait, 
		sincelaststats_cmds = tmp.sincelaststats_cmds,
		sincelaststats_cmspersec = tmp.sincelaststats_cmdspersec, 
		sincelaststats_elaspsed_time = tmp.sincelaststats_elapsed_time, 
		sincelaststats_reader_fetch = tmp.sincelaststats_fetch, 
		sincelaststats_reader_wait = tmp.sincelaststats_fetch_wait 
		from (select *  from openxml (@xmldoc, ''/'', 2)
		with (state int ''stats/@state'',
		cmds int ''stats/@cmds'',
		callstogetreplcmds int ''stats/@callstogetreplcmds'',
		[fetch] int ''stats/@fetch'',
		fetch_wait int ''stats/@wait'',
		sincelaststats_cmds int ''stats/sincelaststats/@cmds'',
		sincelaststats_cmdspersec decimal ''stats/sincelaststats/@cmdspersec'',
		sincelaststats_elapsed_time int ''stats/sincelaststats/@elapsedtime'',
		sincelaststats_fetch int ''stats/sincelaststats/@fetch'',
		sincelaststats_fetch_wait int ''stats/sincelaststats/@wait'')) tmp
		where ' + @replstattroubleshooting_tablename + '.id = '+ convert(varchar, @rowid)

		exec sp_executesql @cmd, N'@xmldoc int', @xmldoc
	end

	-- transfer the xml data of which the state marked as 3.
	else if @getstate = '3'
	begin
		set @cmd = 'update ' + @replstattroubleshooting_tablename + ' set  
		[state] = tmp.[state],
		writer_write = tmp.write,
		writer_wait = tmp.write_wait,
		sincelaststats_elaspsed_time = tmp.sincelaststats_elapsed_time,
		sincelaststats_writer_write	= tmp.sincelaststats_write,
		sincelaststats_writer_wait	= tmp.sincelaststats_write_wait
		from (select * from openxml (@xmldoc, ''/'', 2)
		with (state int ''stats/@state'',
		write int ''stats/@write'',
		write_wait int ''stats/@wait'',
		sincelaststats_elapsed_time int ''stats/sincelaststats/@elapsedtime'',
		sincelaststats_write int ''stats/sincelaststats/@write'',
		sincelaststats_write_wait int ''stats/sincelaststats/@wait'')) tmp
		where ' + @replstattroubleshooting_tablename + '.id = '+ convert(varchar, @rowid)

		exec sp_executesql @cmd, N'@xmldoc int', @xmldoc
	end
	exec sp_xml_removedocument @xmldoc output
end
go


raiserror('creating procedure proc_perfstat_data_process', 0,1) with nowait
go
--
-- name: proc_perfstat_data_process
--
-- description:  this procedure is to cast xml format statistics from agent history tables into 
--				 table format data in replstatssourceinfo_<distribution_db_name> combined with related help info 
--				 from MSdistribution_history, MSdistribution_agents, MSpublications, MSsubscriptions, MSarticles and master.sys.servers.
--
-- parameters:	@agent_name : name of agent we want to trouble shoot 
--				@publisher_db : name of publisher database we want to trouble shoot 
--				@publication_name : name of publication we want to trouble shoot 
--				@timeperiod int : time duration of data we want to trouble shoot
--				@backup_troubleshooting : 0 for live mode trouble shooting, 1 for back up troubleshooting.
--
-- security: this is a public interface object.
--
create procedure proc_perfstat_data_process
(
@agent_name sysname = '%',
@publisher_db sysname = '%',
@publication_name sysname = '%',
@timeperiod int = -1,
@backup_troubleshooting bit = 0
)
as
begin
	declare @distdbname sysname
	declare @xpath nvarchar(max)
	declare @rowid int
	declare @agent_id int
	declare @agent_type nvarchar(25)
	declare @stat_info_tablename nvarchar(max)
	declare @replstattroubleshooting_tablename nvarchar(128)
	-- iterate every distribution database we marked in proc_perfstat_env_set_up,  generate correlated data and stored into 
	-- replstatssourceinfo_<distribution_db_name> tables
	declare distdb cursor for select name from tempdb.dbo.distdbinfo 
	open distdb
	fetch next from distdb into @distdbname
	
	while (@@fetch_status <> -1)
	begin
		-- generate filter for logreader agent and distribution agent seperately based on the input conditions.
		set @stat_info_tablename = 'tempdb.dbo.' + quotename('replstatssourceinfo_' + @distdbname)
		set @replstattroubleshooting_tablename = 'tempdb.dbo.' + quotename(concat('replstattroubleshooting_', @distdbname))
		declare @filter_lr nvarchar(300) = 'where lrhist.comments like ''<stats%'' '
		declare @filter_d nvarchar(300) =  'where dhist.comments like ''<stats%'' '

		if (@timeperiod > 0)
		begin
			set @filter_lr = @filter_lr + concat(' and datediff(hour, [time], getdate()) < ', @timeperiod)
			set @filter_d = @filter_d + concat(' and datediff(hour, [time], getdate()) < ', @timeperiod)
		end 

		if (@agent_name  <> '%')
		begin
			set @filter_lr = @filter_lr + ' and la.name = ' + quotename(@agent_name, '''') 
			set @filter_d = @filter_d + ' and da.name = ' + quotename(@agent_name, '''')
		end

		if(@publisher_db <> '%')
		begin
			set @filter_lr = @filter_lr + ' and la.publisher_db = ' + quotename(@publisher_db, '''') 
			set @filter_d = @filter_d + ' and da.publisher_db = ' + quotename(@publisher_db, '''') 
		end

		-- publication name is only available for distribution agent.
		if(@publication_name <> '%')
		begin
			set @filter_d = @filter_d + ' and pub.publication = ' + quotename(@publication_name, '''') 
		end

		--live
		-- if its in live mode, the input database is not a restored back up db, and recovered distribution database is not in AG group
		if (@backup_troubleshooting = 0 and object_id(@distdbname + '..MSreplservers') is null)
		begin
			set @filter_lr = concat('left join master.sys.servers srvs on srvs.server_id = la.publisher_id ', @filter_lr)
			set @filter_d =  concat('left join master.sys.servers srvs on srvs.server_id = da.publisher_id left join master.sys.servers srvs2 on srvs2.server_id = sub.subscriber_id ', @filter_d)
		end
		else if object_id(@distdbname + '..MSreplservers') is not null
		begin
			set @filter_lr = concat('left join ['+ @distdbname + ']..MSreplservers srvs on srvs.server_id = la.publisher_id ', @filter_lr)
			set @filter_d =  concat('left join ['+ @distdbname + ']..MSreplservers srvs on srvs.server_id = da.publisher_id left join ['+ @distdbname + ']..MSreplservers srvs2 on srvs2.server_id = sub.subscriber_id ', @filter_d)
		end
		else 
		begin
			-- create a fake one if there is no server table in back up file
			if object_id(@distdbname + '.dbo.servers') is null
				exec ('create table [' + @distdbname + '].dbo.servers (server_id int, name nvarchar(50))')
			set @filter_lr = concat('left join [' + @distdbname + '].dbo.servers srvs on srvs.server_id = la.publisher_id ', @filter_lr)
			set @filter_d =  concat('left join [' + @distdbname + '].dbo.servers srvs on srvs.server_id = da.publisher_id left join [' + @distdbname+'].dbo.servers srvs2 on srvs2.server_id = sub.subscriber_id ', @filter_d)
		end

		-- generate help info except casting the xml statistic data into table format for logreader agent and distribution agent seperately. 
		exec ('insert into ' + 'tempdb.dbo.replstatssourceinfo_' + @distdbname +' (time, comments, agent_id,agent_type, agent_name, publisher_id, publisher_db, publisher_name)'+'
		select lrhist.time, lrhist.comments, lrhist.agent_id, ''logreader'', la.name, la.publisher_id, la.publisher_db, srvs.name
		from [' + @distdbname + ']..MSlogreader_history lrhist 
		left join [' + @distdbname + ']..MSlogreader_agents la
		on lrhist.agent_id = la.id
		' + @filter_lr)

		exec('insert into '+ @stat_info_tablename +' (time, comments, agent_id, agent_type, agent_name, publisher_id, publisher_db, publisher_name,
			subscriber_id, subscriber_name, subscription_database, article_id, article_name, publication_id, publication_name)
		select dhist.time, dhist.comments, dhist.agent_id, ''distribution'', da.name, da.publisher_id, da.publisher_db, srvs.name, 
		sub.subscriber_id, srvs2.name, sub.subscriber_db, sub.article_id, arc.article, sub.publication_id, pub.publication
		from ['+ @distdbname + ']..MSdistribution_history dhist 
		left join ['+ @distdbname + ']..MSdistribution_agents da
		on dhist.agent_id = da.id
		left join ['+ @distdbname + ']..MSsubscriptions sub
		on dhist.agent_id = sub.agent_id
		left join ['+ @distdbname + ']..MSarticles arc
		on arc.article_id = sub.article_id
		left join ['+ @distdbname + ']..MSpublications pub
		on pub.publication_id = sub.publication_id
		'+@filter_d)

		-- generate replstattroubleshooting table for trouble shooting
		exec('select * into ' + @replstattroubleshooting_tablename + ' from (select id, time, agent_type, agent_id, agent_name, state, work, idle, cmds, callstogetreplcmds, reader_fetch, reader_wait, writer_write, writer_wait, sincelaststats_elaspsed_time,
		sincelaststats_work, sincelaststats_cmds, sincelaststats_cmspersec, sincelaststats_reader_fetch, sincelaststats_reader_wait,
		sincelaststats_writer_write, sincelaststats_writer_wait, comments, ROW_NUMBER() OVER(PARTITION BY time, comments ORDER BY id DESC) rn from ' + @stat_info_tablename + ') a  where rn = 1')

		-- call proc_perfstat_transfer_xml_data_to_table to cast the xml statistical data into table format 
		-- and store data in replstattroubleshooting_<distribution_db_name> table
		exec('declare perfstats cursor for select comments, id from ' + @replstattroubleshooting_tablename)
		open perfstats
		fetch next from perfstats into @xpath, @rowid
			while (@@fetch_status <> -1)
				begin
					if (@@fetch_status <> -2)
						begin
							exec proc_perfstat_transfer_xml_data_to_table @replstattroubleshooting_tablename, @xpath, @rowid
						end
					fetch next from perfstats into @xpath, @rowid
				end
		close perfstats
		deallocate perfstats		
		fetch next from distdb into @distdbname
	end
	close distdb 
	deallocate distdb
end
go


raiserror('creating procedure proc_perfstat_diagnose', 0,1) with nowait
go
--
-- name: proc_perfstat_diagnose
--
-- description: this procedure is to find out the exceptional rows in replstatssourceinfo_<distribution_db_name> table which 
-- have higher wait time (for now we just pick up top 5) or the state of the row has been marked as 2 or 3, output these exceptional rows into distagentissues_<distribution database name>
-- and logragentissues_<distribution database name> combined with the description in issuesdescription (table created in proc_perfstat_env_set_up)
-- 
-- parameters:	none
--
-- security: this is a public interface object.
--
create procedure proc_perfstat_diagnose
as
begin
	declare @stat_info_tablename nvarchar(128)
	declare @replstattroubleshooting_tablename nvarchar(128) 
	declare @distdbname sysname
	declare @agentsinfo as table (
			agent_name nvarchar(100),
			agent_type nvarchar(50)
	)
	declare @agent_name nvarchar(100)
	declare @agent_type nvarchar(50)

	declare @row_count_dist int = 0
	declare @row_count_lr int = 0

	-- iterate every replstatssourceinfo_<distribution database name> table
	declare distdb cursor for select name from tempdb.dbo.distdbinfo
	open distdb
	fetch next from distdb into @distdbname
	set @stat_info_tablename = 'dbo.replstatssourceinfo_' + @distdbname
	set @replstattroubleshooting_tablename = 'tempdb.dbo.' + quotename(concat('replstattroubleshooting_', @distdbname))

	while @@fetch_status = 0 
	begin
		-- result table name 
		declare @logragent_issue nvarchar(50) =  'logragentissues_' + @distdbname 
		declare @distagent_issue nvarchar(50) =  'distagentissues_' + @distdbname

		declare @logragent_issue_replinfo nvarchar(80) =  @logragent_issue + '_replinfo'
		declare @distagent_issue_replinfo nvarchar(80) =  @distagent_issue + '_replinfo'

		--- for rows of which the state has been marked as 2, 
		--- raised when an agentâ€™s reader thread waits long time.
		-- trouble shoot logreader agent's reader thread
		exec('insert into ' + @logragent_issue + '(agent_id, agent_name,
				state, cmds, callstogetreplcmds, sincelaststats_reader_fetch, sincelaststats_reader_wait, time, 
				description,delayed_threads, reader_fetch, reader_wait, sincelaststats_cmds, sincelaststats_cmspersec, sincelaststats_elaspsed_time, comments)
				select repld.agent_id, repld.agent_name, repld.[state], repld.cmds, repld.callstogetreplcmds, repld.[sincelaststats_reader_fetch],repld.[sincelaststats_reader_wait],
				repld.time,iss.[description],iss.delayed_thread, repld.reader_fetch, repld.reader_wait, repld.sincelaststats_cmds, repld.sincelaststats_cmspersec, repld.sincelaststats_elaspsed_time, repld.comments 
				from  ' + @replstattroubleshooting_tablename + '  repld, issuesdescription iss
				where repld.[state] = 2 and repld.agent_type = ''logreader'' and iss.issuedescription_id = 1')

		-- trouble shoot distribution agent's reader thread
		exec('insert into '+ @distagent_issue +' ( agent_id, agent_name, 
				state, cmds, callstogetreplcmds, sincelaststats_writer_write, sincelaststats_writer_wait, time, description,delayed_threads, sincelaststats_cmds, sincelaststats_cmspersec, sincelaststats_elaspsed_time, comments ) 
				select repld.agent_id, repld.agent_name, repld.[state], repld.cmds, repld.callstogetreplcmds, repld.sincelaststats_writer_write,repld.sincelaststats_writer_wait,
				repld.time, iss.[description], iss.delayed_thread , repld.sincelaststats_cmds, repld.sincelaststats_cmspersec, repld.sincelaststats_elaspsed_time,  repld.comments  
				from  '+ @replstattroubleshooting_tablename +'  repld, issuesdescription iss
				where repld.[state] = 2 and repld.agent_type = ''distribution'' and iss.issuedescription_id = 3')
		
		-- for rows of which the state has been marked as 3, raised only by the log reader agent 
		-- when the writer thread waits longer time.
		exec('insert into '+ @logragent_issue +' ( agent_id, agent_name,
				state,sincelaststats_writer_write,sincelaststats_writer_wait,time,
				 description,delayed_threads,writer_write,writer_wait,sincelaststats_elaspsed_time, comments)
				select repld.agent_id, repld.agent_name, repld.[state], repld.sincelaststats_writer_write,repld.sincelaststats_writer_wait,
				repld.time,iss.[description],iss.delayed_thread, repld.writer_write, repld.writer_wait, repld.sincelaststats_elaspsed_time, repld.comments 
				from ' + @replstattroubleshooting_tablename +' repld, issuesdescription iss
				where repld.[state] = 3 and iss.issuedescription_id = 2')

		
		--- for rows of which the state has been marked as 1, only for 
		insert into @agentsinfo (agent_name, agent_type) exec('select distinct(agent_name), agent_type  from ' + @replstattroubleshooting_tablename)


		declare agents cursor for select agent_name, agent_type from @agentsinfo
		open agents
		fetch next from agents into @agent_name, @agent_type
		while @@fetch_status = 0 
		begin
			-- logreader
			if (@agent_type = 'logreader')
			begin
				-- troubleshooting of logreader agent's  reader thread
				exec('insert into '+ @logragent_issue +' ( agent_id, agent_name,
				 state,cmds, callstogetreplcmds, sincelaststats_reader_fetch, sincelaststats_reader_wait, time, 
				 description,delayed_threads, sincelaststats_writer_write, sincelaststats_writer_wait,reader_fetch,reader_wait,writer_write,writer_wait,sincelaststats_work
				,sincelaststats_cmds,sincelaststats_cmspersec,sincelaststats_elaspsed_time, comments) 
				select top 5 repld.agent_id, repld.agent_name, repld.[state],  repld.cmds, repld.callstogetreplcmds, repld.sincelaststats_reader_fetch, repld.sincelaststats_reader_wait,
				repld.time,iss.[description], iss.delayed_thread, repld.sincelaststats_writer_write,repld.sincelaststats_writer_wait,repld.reader_fetch,repld.reader_wait,repld.writer_write,repld.writer_wait,
				repld.sincelaststats_work, repld.sincelaststats_cmds, repld.sincelaststats_cmspersec, repld.sincelaststats_elaspsed_time, repld.comments 
				from ' + @replstattroubleshooting_tablename + ' repld, issuesdescription iss
				where repld.sincelaststats_reader_wait <> 0 and repld.[state] = 1 and repld.agent_name = '''+ @agent_name + ''' and iss.issuedescription_id = 1 order by repld.sincelaststats_reader_wait desc')
				-- troubleshooting of logreader agent's  writer thread
				exec('insert into '+ @logragent_issue +' ( agent_id, agent_name,
				state,cmds, callstogetreplcmds,sincelaststats_writer_write,sincelaststats_writer_wait,time,
				description,delayed_threads, sincelaststats_reader_fetch, sincelaststats_reader_wait,reader_fetch,reader_wait,writer_write,writer_wait,sincelaststats_work
				,sincelaststats_cmds,sincelaststats_cmspersec,sincelaststats_elaspsed_time, comments) 
				select top 5 repld.agent_id, repld.agent_name, repld.[state], repld.cmds, repld.callstogetreplcmds, repld.sincelaststats_writer_write,repld.sincelaststats_writer_wait,
				repld.time,iss.[description],iss.delayed_thread, repld.sincelaststats_reader_fetch, repld.sincelaststats_reader_wait, repld.reader_fetch,repld.reader_wait,repld.writer_write,repld.writer_wait,
				repld.sincelaststats_work, repld.sincelaststats_cmds, repld.sincelaststats_cmspersec, repld.sincelaststats_elaspsed_time, repld.comments
				from ' + @replstattroubleshooting_tablename + ' repld, issuesdescription iss
				where repld.sincelaststats_writer_wait <> 0 and repld.[state] = 1 and repld.agent_name = '''+ @agent_name +''' and iss.issuedescription_id = 2 order by repld.sincelaststats_writer_wait desc')
			end
			else 
			begin
				-- troubleshooting of distribution agent's  reader thread	
				exec('insert into '+ @distagent_issue +' (agent_id, agent_name,
				state,cmds, callstogetreplcmds,sincelaststats_reader_fetch, sincelaststats_reader_wait, time, 
				description,delayed_threads, sincelaststats_writer_write, sincelaststats_writer_wait,reader_fetch,reader_wait,writer_write,writer_wait,sincelaststats_work
				,sincelaststats_cmds,sincelaststats_cmspersec,sincelaststats_elaspsed_time, comments) 
				select top 5  repld.agent_id, repld.agent_name, repld.[state], repld.cmds, repld.callstogetreplcmds, repld.sincelaststats_reader_fetch, repld.sincelaststats_reader_wait,
				repld.time,iss.[description],iss.delayed_thread, repld.sincelaststats_writer_write, repld.sincelaststats_writer_wait ,repld.reader_fetch,repld.reader_wait,repld.writer_write,repld.writer_wait,
				repld.sincelaststats_work, repld.sincelaststats_cmds, repld.sincelaststats_cmspersec, repld.sincelaststats_elaspsed_time , repld.comments 
				from  ' + @replstattroubleshooting_tablename + '  repld, issuesdescription iss
				where repld.sincelaststats_reader_wait <> 0 and repld.[state] = 1 and repld.agent_name = '''+ @agent_name +''' and iss.issuedescription_id = 3 order by repld.sincelaststats_reader_wait desc')

				-- troubleshooting of distribution agent's  writer thread
				exec('insert into '+ @distagent_issue +' (agent_id, agent_name,
				state,cmds, callstogetreplcmds,sincelaststats_writer_write, sincelaststats_writer_wait, time, 
				description,delayed_threads, sincelaststats_reader_fetch, sincelaststats_reader_wait,reader_fetch,reader_wait,writer_write,writer_wait,sincelaststats_work
				,sincelaststats_cmds,sincelaststats_cmspersec,sincelaststats_elaspsed_time, comments ) 
				select top 5 repld.agent_id, repld.agent_name, repld.[state],repld.cmds, repld.callstogetreplcmds, repld.sincelaststats_writer_write,repld.sincelaststats_writer_wait,
				repld.time,iss.[description],iss.delayed_thread, repld.sincelaststats_reader_fetch, repld.sincelaststats_reader_wait, repld.reader_fetch,repld.reader_wait,repld.writer_write,repld.writer_wait,
				repld.sincelaststats_work, repld.sincelaststats_cmds, repld.sincelaststats_cmspersec, repld.sincelaststats_elaspsed_time, repld.comments  
				from  ' + @replstattroubleshooting_tablename + '  repld, issuesdescription iss
				where  repld.sincelaststats_reader_wait <> 0 and repld.[state] = 1 and repld.agent_name = '''+ @agent_name +''' and iss.issuedescription_id = 4 order by repld.sincelaststats_writer_wait desc')
			end
			fetch next from agents into @agent_name, @agent_type
		end
		close agents 
		deallocate agents
		
		declare @droptablecmd nvarchar(128)
		if object_id(@logragent_issue_replinfo, 'u') is not null
		begin
			set @droptablecmd  = concat('drop table ', @logragent_issue_replinfo)
			exec(@droptablecmd)
		end

		if object_id(@distagent_issue_replinfo, 'u') is not null
		begin
			set @droptablecmd  = concat('drop table ', @distagent_issue_replinfo)
			exec(@droptablecmd)			
		end

		-- generate repl info table  distagentissues_<dist db name>_replinfo and logragentissues_<dist db name>_replinfo
		exec ('select lgr.agent_id	,lgr.agent_name	,lgr.state,lgr.cmds ,lgr.callstogetreplcmds ,lgr.reader_fetch,lgr.reader_wait,lgr.writer_write,
		lgr.writer_wait	,lgr.sincelaststats_work,lgr.sincelaststats_cmds,lgr.sincelaststats_cmspersec,lgr.sincelaststats_elaspsed_time	,lgr.sincelaststats_reader_fetch	,
		lgr.sincelaststats_reader_wait,lgr.sincelaststats_writer_write,lgr.sincelaststats_writer_wait,lgr.description,lgr.delayed_threads,lgr.time,src.publisher_id,
		src.publisher_name,src.publisher_db into ' + @logragent_issue_replinfo + ' from ' + @logragent_issue + ' lgr inner join ' + @stat_info_tablename + ' src on lgr.time = src.time and lgr.comments = src.comments')
		
		exec ('select dist.agent_id,dist.agent_name	,dist.state,dist.cmds ,dist.callstogetreplcmds ,dist.reader_fetch,dist.reader_wait,dist.writer_write,
		dist.writer_wait	,dist.sincelaststats_work,dist.sincelaststats_cmds,dist.sincelaststats_cmspersec,dist.sincelaststats_elaspsed_time	,dist.sincelaststats_reader_fetch	,
		dist.sincelaststats_reader_wait,dist.sincelaststats_writer_write,dist.sincelaststats_writer_wait,dist.description,dist.delayed_threads,dist.time,src.publisher_id,
		src.publisher_name,src.publisher_db, src.subscriber_id, src.subscriber_name,src.subscription_database,src.article_id,src.article_name, src.publication_id, src.publication_name
		into ' + @distagent_issue_replinfo + ' 
		from ' + @distagent_issue + ' dist inner join ' + @stat_info_tablename + ' src on dist.time = src.time and dist.comments = src.comments') 

		-- drop the replstatssourceinfo_<distdb>
		exec ('drop table ' + @replstattroubleshooting_tablename)
		

		-- generate the output info
		declare @cnt int
		declare @sqlcommand_dist nvarchar(1000) = 'select @cnt = count(*) from ' + @distagent_issue
		declare @sqlcommand_lr nvarchar(100) = 'select @cnt = count(*) from ' + @logragent_issue
		execute sp_executesql @sqlcommand_lr, N'@cnt int OUTPUT', @cnt  = @row_count_lr OUTPUT
		execute sp_executesql @sqlcommand_dist, N'@cnt int OUTPUT', @cnt = @row_count_dist OUTPUT
		print '--------------------------Result Statistics of distribution database: ' + @distdbname + '--------------------------'
		print convert(varchar, @row_count_lr) + ' exceptional rows identified in ' + @logragent_issue
		print convert(varchar, @row_count_dist)+ ' exceptional rows identified in ' + @distagent_issue		
		fetch next from distdb into @distdbname	
	end
	close distdb 
	deallocate distdb
end
go

raiserror('creating procedure proc_perfstat', 0,1) with nowait
go
--
-- name: proc_perfstat
--
-- description: this procedure is the interface for users to go through the trouble shooting process. 
-- 
-- parameters:	@distribution_data : name of distribution database or restored distribution database name
--				@agent_name : name of agent we want to trouble shoot.
--				@publisher_db : name of publisher database we want to trouble shoot. 
--				@publication_name : name of publication we want to trouble shoot.
--				@timeperiod int : duration of data we want to trouble shoot.
--				@backup_troubleshooting: 0 for directly troubleshooting on the targeted distributor server.
--										 1 for troubleshooting based on the distribution database back up file.
--
-- returns: 0 - succeed
--          1 - failed
--
-- security: this is a public interface object.
--
create procedure proc_perfstat
(
	@distribution_data sysname = '%',
	@agent_name sysname = '%',
	@publisher_db sysname = '%',
	@publication_name sysname = '%',
	@timeperiod int = -1,
	@backup_troubleshooting bit = 0
)
as
begin
	declare @is_env_set_up bit = 0
	exec @is_env_set_up = proc_perfstat_env_set_up @distribution_data, @backup_troubleshooting
	if @is_env_set_up = 1
		return (1)
	---- generate source data.
	exec proc_perfstat_data_process @agent_name, @publisher_db, @publication_name, @timeperiod, @backup_troubleshooting
	---- locate the exceptional rows.
	exec proc_perfstat_diagnose
	return (0) 
end
go

exec proc_perfstat
-- PerfStat script end



-- PerfStat.sql result tables, which are already generated in the tempdb
declare @resulttable sysname = ''
declare cur cursor for SELECT TABLE_NAME FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME like N'distagentissues%' or TABLE_NAME like N'logragentissues%' or TABLE_NAME like N'replstatssourceinfo%'
open cur
fetch next from cur into @resulttable
while @@fetch_status = 0 
begin
	declare @command varchar(max) = 'select * from [tempdb].[dbo].['+ @resulttable +'] (nolock)'
	exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor', @command
	print @resulttable
	fetch next from cur into @resulttable
end
close cur    
deallocate cur


exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [tempdb].[dbo].[issuesdescription] (nolock)'
go

exec tempdb.dbo.ReplPssdiagExecuteCommandOnDbType 'Distributor','select * from [tempdb].[dbo].[distdbinfo] (nolock)'
go





-- Clean up
use tempdb
go
if (object_id('ReplPssdiagExecuteCommandOnDbType') IS NOT NULL)
	drop proc dbo.ReplPssdiagExecuteCommandOnDbType
go



print '-> End Time'
select [getdate]=getdate()

