/*
Author:		tzakir@microsoft.com
Purpose:	Change Data Capture Script for PSSDiag
Date:		1/6/2017
Note:		
Version:	1.0 
Change List:
*/

USE master
go

SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @StartTime datetime
select @@version as 'Version'
select GETDATE() as 'RunDateTime', GETUTCDATE() as 'RunUTCDateTime', SYSDATETIMEOFFSET() as 'SysDateTimeOffset'

select @@servername as 'ServerName'
PRINT '-- CDC enabled databases --' 
SELECT * 
FROM sys.databases where is_cdc_enabled = 1
order by name

-- Loop Through DBs and Gather CT information specific to each DB
DECLARE tnames_cursor CURSOR
FOR SELECT
	db.name AS name
FROM sys.databases db 
where is_cdc_enabled = 1
order by db.name

OPEN tnames_cursor;
DECLARE @dbname sysname;
DECLARE @cmd3 nvarchar(1024); -- New Command
FETCH NEXT FROM tnames_cursor INTO @dbname;
WHILE (@@FETCH_STATUS = 0)
BEGIN

	select @dbname = RTRIM(@dbname);
	EXEC ('USE [' + @dbname + ']');
		BEGIN
		PRINT ''
		PRINT '====================================================================================='
		PRINT 'Begin Database: ' + @dbname
		SELECT @StartTime = GETDATE()
		PRINT 'Start Time : ' + CONVERT(Varchar(50), @StartTime)
		
		PRINT ''
		PRINT '-- Jobs created by CDC --'
		EXEC ('select 
			j.job_id as job_id,
            j.job_type as job_type,
            s.name as job_name,
            j.maxtrans as maxtrans,
            j.maxscans as maxscans,
            j.continuous as continuous,
            j.pollinginterval as pollinginterval,
            j.retention as retention,
            j.threshold as threshold
        from msdb.dbo.cdc_jobs j inner join msdb.dbo.sysjobs s
        on j.job_id = s.job_id
        where database_id = db_id('+ '''' + @dbname + '''' + ')');

		PRINT ''
		PRINT 'Tables enabled for CDC'
		EXEC ('Select * 
			from [' + @dbname + '].sys.tables where is_tracked_by_cdc = 1;');	

		PRINT ''
		PRINT 'CDC Metdata Tables in the CDC Schema'
		EXEC ('Select ss.name + ' + '''' + '.' + '''' + '+ so.name as CDCObjectnames, so.* 
				from [' + @dbname + '].sys.sysobjects so join [' + @dbname + '].sys.schemas ss on so.uid=ss.schema_id where ss.name=' + '''' + 'cdc' + '''' + 'and so.xtype=' + '''' + 'U' + '''');	

		PRINT ''
		PRINT 'CDC Procedures in the CDC Schema'
		EXEC ('select ss.name + ' + '''' + '.' + '''' + '+ so.name as CDCObjectnames, so.* 
		from [' + @dbname + '].sys.sysobjects so join [' + @dbname + '].sys.schemas ss on so.uid=ss.schema_id where ss.name=' + '''' + 'cdc' + '''' + 'and so.xtype=' + '''' + 'P' + '''');	

		PRINT ''
		PRINT 'Index column associated with a change table. The index columns are used by change data capture to uniquely identify rows in the source table'
		EXEC ('Use [' + @dbname + ']; Select object_name(object_id) as CTTableName,* 
		from  [' + @dbname + '].cdc.index_columns
		order by 1');	

		PRINT ''
		PRINT 'DDL changes (Alter Table) done to CDC enabled Tables'
		EXEC ('Select * 
		from [' + @dbname + '].cdc.ddl_history
		order by ddl_time desc')	

		--Newest records
		--Parent table storing information for each transaction have associated change in change table.
		--Think of it as msrepl_Transactions table in TReplication
		--Records mapping between log sequence numbers (LSNs) and the date and time when the transaction happened
		PRINT ''
		PRINT 'Newest 100 cdc.lsn_time_mapping'
		EXEC ('Select top 100 * 
		from [' + @dbname + '].cdc.lsn_time_mapping
		order by tran_begin_time desc')	

		PRINT ''
		PRINT 'Oldest 100 cdc.lsn_time_mapping'
		EXEC ('Select top 100 * 
		from [' + @dbname + '].cdc.lsn_time_mapping
		order by tran_begin_time asc')	

		PRINT ''
		PRINT 'Top 200 dm_cdc_log_scan_sessions'
		EXEC ('select  top 200 * 
		from [' + @dbname + '].sys.dm_cdc_log_scan_sessions
		order by end_time desc')	

		PRINT ''
		PRINT 'Top 100 dm_cdc_errors'
		EXEC ('select  top 100 * 
			from [' + @dbname + '].sys.dm_cdc_errors
			order by entry_time desc ')	

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

go
