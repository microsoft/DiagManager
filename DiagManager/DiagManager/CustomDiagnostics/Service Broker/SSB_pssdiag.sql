/*
Author:		EricBu@Microsoft.com and wcarroll@microsoft.com
Purpose:	Service Broker Script for PSSDiag
Date:		05/18/2015
Note:		Set osql -w 8000 in order to display entire definition of activation stored procedures. Save Output as text. 
Version:	2.0 
Change List:
	EricBu - Changed table delimiter so tables can be imported via SQL Nexus Custom Row Importer
	EricBu - Changed all code to NOLOCKs to reduce blocking
	EricBu - Changed sys.database query to only return databases with SSB activated.
	EricBu - Changed sys.dm_broker_queue_monitors to show current state, last activation, current backlog in transmission queue
	EricBu - Changed COUNT(*) to point to meta data rather than table to reduce data collection time/size as we don't need the count to be 100% accurate.
	EricBu - Changed output to be more readable.
	EricBu - Changed the sys.transmission_queue output to remove the Message field which likely will have PPI information in it.
	EricBu - Added DB_NAME() column to sys.transmission and sys.conversation_endpoints queries, so custom importer will import all data from each SSB DB and we can query on them.
	EricBu - Added time to track how long it takes to gather data from each database. We may spot performance issues with gathering data this way.
	EricBu - Changed context of the Queue Monitor Query to the Database Context
	EricBu - Added GROUPing Counts to sys.transmission_queue and sys.conversation_endpoints.
	EricBu - Fixed DATEDIFF() call for the SSB Database specific time.
*/


USE master
go

SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON;
DECLARE @StartTime datetime
select @@version as 'Version'
select GETDATE() as 'RunDateTime', GETUTCDATE() as 'RunUTCDateTime', SYSDATETIMEOFFSET() as 'SysDateTimeOffset'

select @@servername as 'ServerName'
PRINT '-- sys.databases --' 
select * from master.sys.databases where is_broker_enabled = 1 and name not in('tempdb', 'model', 'AdventureWorks', 'AdventureWorksDW')
PRINT ''

PRINT '-- sys.dm_broker_activated_tasks --' 
select * from sys.dm_broker_activated_tasks
PRINT ''

PRINT '-- sys.dm_broker_connections --' 
select * from sys.dm_broker_connections
PRINT ''
PRINT '-- COUNT Broker Connections --'
SELECT count(*) as Cnt, state_desc, login_state_desc from sys.dm_broker_connections GROUP BY state_desc, login_state_desc ORDER BY state_desc 
PRINT ''

PRINT '-- sys.dm_broker_forwarded_messages --' 
select * from sys.dm_broker_forwarded_messages
PRINT ''

PRINT '-- sys.service_broker_endpoints --' 
select * from sys.service_broker_endpoints
PRINT ''

PRINT '-- sys.tcp_endpoints --' 
select * from sys.tcp_endpoints
PRINT ''

PRINT '-- sys.certificates --' 
select * from sys.certificates
PRINT ''

PRINT '-- sys.database_mirroring --' 
select * from sys.database_mirroring where mirroring_guid is not null
PRINT ''

PRINT '-- sys.dm_db_mirroring_connections --' 
select * from sys.dm_db_mirroring_connections
PRINT ''

PRINT '-- sys.dm_os_memory_clerks (broker) --'  
select * from sys.dm_os_memory_clerks where type like '%BROKER%' order by type desc

-- Loop Through DBs and Gather SSB information specific to each DB
DECLARE tnames_cursor CURSOR
FOR SELECT name 
	FROM master.sys.databases 
	WHERE is_broker_enabled = 1 
	and state = 0 
	and name not in('tempdb', 'model', 'AdventureWorks', 'AdventureWorksDW')
	ORDER BY [name]
OPEN tnames_cursor;
DECLARE @dbname sysname;
DECLARE @SCI int; -- Checking for Broker activity
DECLARE @cmd3 nvarchar(1024); -- New Command
FETCH NEXT FROM tnames_cursor INTO @dbname;
WHILE (@@FETCH_STATUS = 0)
BEGIN
	SELECT @SCI = 0; -- service_contract_id
	select @dbname = RTRIM(@dbname);
	EXEC ('USE [' + @dbname + ']');
	SELECT @cmd3 = N'SELECT @SCI_OUT = MAX(service_contract_id) FROM ' + @dbname + '.sys.service_contracts';
	EXEC sp_executesql @cmd3, N'@SCI_OUT INT OUTPUT', @SCI_OUT = @SCI OUTPUT; 
	IF @SCI > 7
		BEGIN
		PRINT ''
		PRINT '====================================================================================='
		PRINT 'Begin Database: ' + @dbname
		SELECT @StartTime = GETDATE()
		PRINT 'Start Time : ' + CONVERT(Varchar(50), @StartTime)
		
		PRINT ''
		PRINT '-- sys.service_message_types --'
		EXEC ('SELECT  * FROM ' + @dbname + '.sys.service_message_types');
		
		-- PRINT ''
		-- PRINT '-- sys.service_contract_message_usages --' 
		-- EXEC ('SELECT * FROM ' + @dbname + '.sys.service_contract_message_usages');
		
		PRINT ''
		PRINT '-- sys.service_contracts --' 
		EXEC ('SELECT * FROM ' + @dbname + '.sys.service_contracts');
		
		-- PRINT ''
		-- print '-- sys.service_contract_usages --' 
		-- EXEC ('SELECT * FROM ' + @dbname + '.sys.service_contract_usages');
		
		PRINT ''
		PRINT '-- sys.service_queues --' 
		EXEC ('SELECT * FROM ' + @dbname + '.sys.service_queues');
		
		-- PRINT ''
		-- PRINT '-- sys.service_queue_usages --' 
		-- EXEC ('SELECT * FROM ' + @dbname + '.sys.service_queue_usages');
		
		PRINT ''
		PRINT '-- sys.services --' 
		EXEC ('SELECT * FROM ' + @dbname + '.sys.services');
		
		PRINT ''
		PRINT '-- sys.routes --' 
		EXEC ('SELECT * FROM ' + @dbname + '.sys.routes');
		
		PRINT ''
		PRINT '-- sys.remote_service_bindings --' 
		EXEC ('SELECT * FROM ' + @dbname + '.sys.remote_service_bindings');
		
		PRINT ''
		PRINT '-- sys.certificates --' 
		EXEC ('SELECT * FROM ' + @dbname + '.sys.certificates');
		
		PRINT ''
		PRINT '-- sys.dm_qn_subscriptions --' 
		EXEC ('SELECT * FROM ' + @dbname + '.sys.dm_qn_subscriptions');

		PRINT '-- sys.dm_broker_queue_monitors, current state, last activation, current backlog in transmission queue --' 
		EXEC ('USE ' + @dbname + ';SELECT t1.name AS [Service_Name],  t3.name AS [Schema_Name],  t2.name AS [Queue_Name],  
		CASE WHEN t4.state IS NULL THEN ''Not available'' 
		ELSE t4.state 
		END AS [Queue_State],  
		CASE WHEN t4.tasks_waiting IS NULL THEN ''--'' 
		ELSE CONVERT(VARCHAR, t4.tasks_waiting) 
		END AS tasks_waiting, 
		CASE WHEN t4.last_activated_time IS NULL THEN ''--'' 
		ELSE CONVERT(varchar, t4.last_activated_time) 
		END AS last_activated_time ,  
		CASE WHEN t4.last_empty_rowset_time IS NULL THEN ''--'' 
		ELSE CONVERT(varchar,t4.last_empty_rowset_time) 
		END AS last_empty_rowset_time, 
		( 
			SELECT COUNT(*) 
			FROM sys.transmission_queue t6 WITH (NOLOCK)
			WHERE (t6.from_service_name = t1.name) 
		) AS [Tran_Message_Count],
		DB_NAME() AS DB_NAME 
		FROM sys.services t1 WITH (NOLOCK) INNER JOIN sys.service_queues t2 WITH (NOLOCK)
		ON ( t1.service_queue_id = t2.object_id )   
		INNER JOIN sys.schemas t3 WITH (NOLOCK) ON ( t2.schema_id = t3.schema_id )  
		LEFT OUTER JOIN sys.dm_broker_queue_monitors t4 WITH (NOLOCK)
		ON ( t2.object_id = t4.queue_id  AND t4.database_id = DB_ID() )  
		INNER JOIN sys.databases t5 WITH (NOLOCK) ON ( t5.database_id = DB_ID() );')
		PRINT ''

		
		PRINT ''
		PRINT 'sys.transmission_queue (toal count, group count, and top 500)'
		
		-- Using count against MetaData columns rather than COUNT(*) becuase it is faster, and we dont' need exact counts
		PRINT '-- TOTAL COUNT sys.transmission_queue --' 
		EXEC ('SELECT p.rows as TQ_Count FROM ' + @dbname + '.sys.objects as o join ' + @dbname + '.sys.partitions as p on p.object_id = o.object_id where o.name = ''sysxmitqueue''')
		-- EXEC ('SELECT count(*) as TQ_Count FROM ' + @dbname + '.sys.transmission_queue with (nolock)');  -- more accurate count
		
		PRINT ''		
		PRINT '-- GROUP COUNT sys.transmission_queue --'
		SELECT COUNT(*) as TQ_GroupCnt, transmission_status FROM sys.transmission_queue GROUP BY transmission_status
		
		PRINT ''
		PRINT 'TOP 500'
		print '-- sys.transmission_queue --' 
		EXEC ('USE ' + @dbname + ';SELECT top 500 conversation_handle, to_service_name, to_broker_instance, from_service_name, 
			service_contract_name, enqueue_time, message_sequence_number, message_type_name, is_conversation_error, 
			is_end_of_dialog, priority, transmission_status, DB_NAME() as DB_Name FROM ' + @dbname + '.sys.transmission_queue with (nolock) order by enqueue_time, message_sequence_number');
		
		PRINT ''
		print 'sys.conversation_endpoints (total count, group count, and top 500)'
		-- Using count against MetaData columns rather than COUNT(*) becuase it is faster, and we dont' need exact counts
		PRINT '-- TOTAL COUNT sys.conversation_endpoints --'
		EXEC ('SELECT p.rows as CE_Count FROM ' + @dbname + '.sys.objects as o join ' + @dbname + '.sys.partitions as p on p.object_id = o.object_id  where o.name = ''sysdesend''')
		-- EXEC ('SELECT count(*) as count FROM ' + @dbname + '.sys.conversation_endpoints with (nolock)');
		
		PRINT ''
		PRINT '-- GROUP COUNT sys.conversation_endpoints --'
		EXEC  ('SELECT COUNT(*) as CE_GroupCnt, state_desc FROM ' + @dbname + '. sys.conversation_endpoints GROUP BY state_desc')
		
		PRINT ''
		PRINT 'TOP 500'
		PRINT '-- sys.conversation_endpoints --'
		EXEC ('USE ' + @dbname + ';SELECT top 500 *, DB_NAME() as DB_Name FROM ' + @dbname + '.sys.conversation_endpoints with (nolock)');
	
	-- Gather Activation Proc Code
	/*
		SET QUOTED_IDENTIFIER OFF;
		DECLARE @cmd nvarchar(1024)
		DECLARE @cmd2 nvarchar(1024)
		select @cmd = 'DECLARE tproc_cursor CURSOR FOR select activation_procedure from ' + @dbname + '.sys.service_queues where activation_procedure is not null'
		EXEC (@cmd)
		OPEN tproc_cursor;
		DECLARE @proc sysname;
		DECLARE @len int
		FETCH NEXT FROM tproc_cursor INTO @proc;
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			select @proc = rtrim(@proc)
			select @len = len(@proc) - 8;
			select @proc = substring(@proc, 8, @len)
			select @proc
			EXEC ("select definition from " + @dbname + ".sys.sql_modules where definition like '%" + @proc + "%'")
			FETCH NEXT FROM tproc_cursor INTO @proc;
		END;
		CLOSE tproc_cursor;
		DEALLOCATE tproc_cursor;
		SET QUOTED_IDENTIFIER ON;
	*/
	
   PRINT ''
   PRINT 'End of Database: ' + @dbname 
   PRINT 'END Time : ' + CONVERT(Varchar(50), GetDate())
   PRINT 'Data Collection Duration in milliseconds for ' + @dbname
   PRINT ''
   SELECT DATEDIFF(millisecond, @StartTime, GETDATE()) as Duration_ms

   PRINT '====================================================================================='
   PRINT '====================================================================================='
   PRINT '' 
   END;
   FETCH NEXT FROM tnames_cursor INTO @dbname;
END;
CLOSE tnames_cursor;
DEALLOCATE tnames_cursor;



