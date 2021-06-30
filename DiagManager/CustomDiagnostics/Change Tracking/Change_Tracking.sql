/*
Purpose:	Change Tracking Script for PSSDiag
Date:		1/3/2020
Note:		
Version:	1.3
Change List: Added CT_oject_id and cleanup_version_commit_time
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
PRINT '-- CT enabled databases --' 
SELECT
	db.name AS change_tracking_db,
	ct.database_id,
	is_auto_cleanup_on,
	retention_period,
	retention_period_units_desc
FROM sys.change_tracking_databases ct
JOIN sys.databases db on
	ct.database_id=db.database_id;
PRINT ''


-- Loop Through DBs and Gather CT information specific to each DB
DECLARE tnames_cursor CURSOR
FOR SELECT
	db.name AS name
FROM sys.change_tracking_databases ct
JOIN sys.databases db on
	ct.database_id=db.database_id;

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
		PRINT '-- Tables involved in CT --'
		EXEC ('SELECT 
				sc.name as tracked_schema_name,
				so.name as tracked_table_name,
				ctt.is_track_columns_updated_on,
				ctt.begin_version /*when CT was enabled, or table was truncated */,
				ctt.min_valid_version /*syncing applications should only expect data on or after this version */ ,
				ctt.cleanup_version /*cleanup may have removed data up to this version */,
				dtc.commit_time as cleanup_version_commit_time /*Cleanup version commit_time*/
				FROM [' + @dbname + '].sys.change_tracking_tables AS ctt
				JOIN [' + @dbname + '].sys.objects AS so on
				ctt.[object_id]=so.[object_id]
				JOIN sys.schemas AS sc on
				so.schema_id=sc.schema_id
				JOIN [' + @dbname + '].sys.dm_tran_commit_table dtc on
				ctt.cleanup_version = dtc.commit_ts;');


		PRINT ''
		PRINT 'Committed transactions in the commit_table --'
		EXEC ('SELECT
				count(*) AS number_commits,
				MIN(commit_ts) AS minimum_commit_ts,
				MIN(commit_time) AS minimum_commit_time,
				MAX(commit_ts) AS maximum_commit_ts,
				MAX(commit_time) AS maximum_commit_time
				FROM [' + @dbname + '].sys.dm_tran_commit_table;');	
	
   		PRINT ''
		PRINT 'Size of internal CT tables --'
		EXEC ('
			select sct1.name as CT_schema,
			sot1.name as CT_table,
			sot1.object_id as CT_oject_id,
			ps1.row_count as CT_rows,
			ps1.used_page_count*8./1024. as CT_used_MB,
			sct2.name as tracked_schema,
			sot2.name as tracked_name,
			ps2.row_count as tracked_rows,
			ps2.used_page_count*8./1024. as tracked_base_table_MB 
			FROM
				[' + @dbname + '].sys.internal_tables it
			JOIN [' + @dbname + '].sys.objects sot1 on it.object_id=sot1.object_id
			JOIN [' + @dbname + '].sys.schemas AS sct1 on
					sot1.schema_id=sct1.schema_id
			JOIN [' + @dbname + '].sys.dm_db_partition_stats ps1 on
				it.object_id = ps1. object_id
				and ps1.index_id in (0,1)
			LEFT JOIN [' + @dbname + '].sys.objects sot2 on it.parent_object_id=sot2.object_id
			LEFT JOIN [' + @dbname + '].sys.schemas AS sct2 on
				sot2.schema_id=sct2.schema_id
			LEFT JOIN [' + @dbname + '].sys.dm_db_partition_stats ps2 on
				sot2.object_id = ps2. object_id
				and ps2.index_id in (0,1)
			WHERE it.internal_type IN (209, 210)
			order by 4 desc ;');	

		PRINT 'Get the Safe and Hardened Cleanup version. Run on 2014 Sp2 / 2016 Sp1 and above--'
		EXEC ( '[' + @dbname + ']..sp_flush_commit_table_on_demand 1;');


		PRINT ''
		PRINT 'Active Snapshot transactions --'
		EXEC ('select top 10 * from [' 
		+ @dbname + '].sys.dm_tran_active_snapshot_database_transactions order by elapsed_time_seconds desc');	

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
