PRINT '-------------------------------------------'
PRINT '---- FullTextSearch Information Collector'
PRINT '---- $Revision: 1 $'
PRINT '---- $Date: 2010/4/19 09:30:05 $'
PRINT '---- $Comments: Only for SQL 2005 & above'
PRINT '---- Version: v3.0'
PRINT '-------------------------------------------'
PRINT ''

PRINT 'Start Time: ' + CONVERT (varchar(30), GETDATE(), 121)

PRINT ''

GO

DECLARE @IsFullTextInstalled int

PRINT ''

PRINT '******** Full-text Service Information ********'
PRINT '***********************************************'
PRINT ''

PRINT '======== FULLTEXTSERVICEPROPERTY (IsFulltextInstalled)'
SET @IsFullTextInstalled = FULLTEXTSERVICEPROPERTY ('IsFulltextInstalled')
PRINT CASE @IsFullTextInstalled 
WHEN 1 THEN '1 - Yes' 
WHEN 0 THEN '0 - No' 
ELSE 'Unknown'
END

IF (@IsFullTextInstalled = 1)
BEGIN

PRINT ''
PRINT '======== FULLTEXTSERVICEPROPERTY (Memory ResourceUsage)'
PRINT CASE FULLTEXTSERVICEPROPERTY ('ResourceUsage')
WHEN 1 THEN '1 - Least Aggressive (Background)'
WHEN 2 THEN '2 - Low'
WHEN 3 THEN '3 - Normal (Default)'
WHEN 4 THEN '4 - High'
WHEN 5 THEN '5 - Most Aggressive (Highest)'
ELSE CONVERT (varchar, FULLTEXTSERVICEPROPERTY ('ResourceUsage'))
END

PRINT ''
PRINT '======== FULLTEXTSERVICEPROPERTY (LoadOSResources)'
PRINT CASE FULLTEXTSERVICEPROPERTY ('LoadOSResources')
WHEN 1 THEN '1 - Loads OS filters and word breakers.'
WHEN 0 THEN '0 - Use only filters and word breakers specific to this instance of SQL Server. Equivalent to ~DOES NOT LOAD OS filters/word-breakers~' 
ELSE CONVERT (varchar, FULLTEXTSERVICEPROPERTY ('LoadOSResources'))
END

PRINT ''
PRINT '======== FULLTEXTSERVICEPROPERTY (VerifySignature)'
PRINT CASE FULLTEXTSERVICEPROPERTY ('VerifySignature')
WHEN 1 THEN '1 - Verify that only trusted, signed binaries are loaded.'
WHEN 0 THEN '0 - Do not verify whether or not binaries are signed. (Unsigned binaries can be loaded)' 
ELSE CONVERT (varchar, FULLTEXTSERVICEPROPERTY ('VerifySignature'))
END

PRINT ''
END

GO

SET NOCOUNT ON

GO

declare @version table (PropertyName nvarchar(30) NOT NULL, PropertyValue nvarchar(100))
declare @count int
declare @execoutput nvarchar(1000)
Insert @version SELECT 'Version', CAST(serverproperty('ProductVersion') AS nvarchar(100))
select @count = count(PropertyValue) from @version where PropertyValue like '9.00.%'
if(@count=1)

begin
PRINT ''
PRINT '******** MSFTESQL Start-up Account ********'
PRINT '*******************************************'
PRINT ''

declare @instancename nvarchar (128), @key nvarchar(1000)
set @instancename = cast ( serverproperty(N'InstanceName') as nvarchar)
if @instancename is not null

begin
set @key='System\CurrentControlSet\Services\MSFTESQL$'+@instancename
exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',@key, N'ObjectName',@execoutput OUTPUT
select 'MSFTESQL$'+ @instancename + ' : ' + @execoutput
end

else

begin
set @key='System\CurrentControlSet\Services\MSFTESQL' 
exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',@key, N'ObjectName',@execoutput OUTPUT
select 'MSFTESQL : ' + @execoutput

end

PRINT ''
PRINT '******** MSFTEUser Group Memebers ********'
PRINT '************************************'
PRINT ''

declare @computername varchar(128)
declare @inst nvarchar (128)
declare @FTSGroup nvarchar(128)
set @inst = cast ( serverproperty(N'InstanceName') as nvarchar)
IF object_id('tempdb..#computername') IS NOT NULL
begin
drop table #computername
end

create table #computername (name varchar(128))
insert into #computername exec master.dbo.xp_cmdshell 'hostname'
--delete from #computername where name is null
set @computername = (select name from #computername)
set @FTSGroup = 'net localgroup SQLServer2005MSFTEUser$' + @computername + '$' + @inst
exec master.dbo.xp_cmdshell @FTSGroup
end
else
begin
PRINT ''
PRINT '******** MSSQLFDLauncher Start-up Account ********'
PRINT '**************************************************'
PRINT ''

declare @instancename2 nvarchar (128), @key2 nvarchar(1000)
set @instancename2 = cast ( serverproperty(N'InstanceName') as nvarchar)
if @instancename2 is not null
begin
set @key2='System\CurrentControlSet\Services\MSSQLFDLauncher$'+@instancename2
exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',@key2, N'ObjectName',@execoutput OUTPUT
select 'MSSQLFDLauncher$'+ @instancename2 + ' : ' + @execoutput
end

else

begin
set @key2='System\CurrentControlSet\Services\MSSQLFDLauncher' 
exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE',@key2, N'ObjectName',@execoutput OUTPUT 
select 'MSSQLFDLauncher : ' + @execoutput
end

PRINT ''
PRINT '******** FDHOST Group Memebers ********'
PRINT '************************************'
PRINT ''

declare @computername2 varchar(128)
declare @inst2 nvarchar (128)
declare @FTSGroup2 nvarchar(128)
set @inst2 = cast ( serverproperty(N'InstanceName') as nvarchar)
IF @inst2 is null
set @inst2 = 'MSSQLSERVER'
IF object_id('tempdb..#computername3') IS NOT NULL
begin
drop table #computername3
end

create table #computername3 (name varchar(128))
insert into #computername3 exec master.dbo.xp_cmdshell 'hostname'
--delete from #computername2 where name is null
set @computername2 = (select name from #computername3 where name is not null)
set @FTSGroup2 = 'net localgroup SQLServerFDHOSTUser$' + @computername2 + '$' + @inst2
exec master.dbo.xp_cmdshell @FTSGroup2
end

SET NOCOUNT OFF

GO

PRINT ''
PRINT '******** Full-Text Catalog Information & Properties ********'
PRINT '************************************************************'
PRINT ''
GO

sp_msforeachdb 'IF EXISTS (select * from [?].sys.fulltext_catalogs) BEGIN PRINT ''======== DatabaseName: ?'' SELECT cat.name AS [CatalogName], cat.fulltext_catalog_id AS [CatalogID],
FULLTEXTCATALOGPROPERTY(cat.name,''LogSize'') AS [ErrorLogSize], 
FULLTEXTCATALOGPROPERTY(cat.name,''IndexSize'') AS [FullTextIndexSize], 
FULLTEXTCATALOGPROPERTY(cat.name,''ItemCount'') AS [ItemCount], 
FULLTEXTCATALOGPROPERTY(cat.name,''UniqueKeyCount'') AS [UniqueKeyCount], 
[PopulationStatus] = CASE 
WHEN FULLTEXTCATALOGPROPERTY(cat.name,''PopulateStatus'') = 0 THEN ''Idle''
WHEN FULLTEXTCATALOGPROPERTY(cat.name,''PopulateStatus'') = 1 THEN ''Full population in progress'' 
WHEN FULLTEXTCATALOGPROPERTY(cat.name,''PopulateStatus'') = 2 THEN ''Paused''
WHEN FULLTEXTCATALOGPROPERTY(cat.name,''PopulateStatus'') = 4 THEN ''Recovering''
WHEN FULLTEXTCATALOGPROPERTY(cat.name,''PopulateStatus'') = 6 THEN ''Incremental population in progress''
WHEN FULLTEXTCATALOGPROPERTY(cat.name,''PopulateStatus'') = 7 THEN ''Building index''
WHEN FULLTEXTCATALOGPROPERTY(cat.name,''PopulateStatus'') = 9 THEN ''Change tracking''
ELSE ''Other Status(3/5/8)''END,
tbl.change_tracking_state_desc AS [ChangeTracking],
FULLTEXTCATALOGPROPERTY(cat.name,''MergeStatus'') AS [IsMasterMergeHappening],
tbl.crawl_type_desc AS [LastCrawlType],
tbl.crawl_start_date AS [LastCrawlSTARTDate],
tbl.crawl_end_date AS [LastCrawlENDDate],
ISNULL(cat.path,N'''') AS [CatalogRootPath] /*, 
CAST((select (case when exists(select distinct object_id from sys.fulltext_indexes fti where cat.fulltext_catalog_id = fti.fulltext_catalog_id and OBJECTPROPERTY(object_id, ''IsTable'')=1) 
then 1 else 0 end)) AS bit) AS [HasFullTextIndexedTables]*/
FROM [?].sys.fulltext_catalogs AS cat 
LEFT OUTER JOIN [?].sys.filegroups AS fg ON cat.data_space_id = fg.data_space_id 
LEFT OUTER JOIN [?].sys.database_principals AS dp ON cat.principal_id=dp.principal_id 
LEFT OUTER JOIN [?].sys.fulltext_indexes AS tbl ON cat.fulltext_catalog_id = tbl.fulltext_catalog_id PRINT '''' END'

GO

PRINT ''
PRINT '******** Full-text Index Information (for each table)********'
PRINT '*************************************************************'
PRINT ''

GO

sp_msforeachdb 'IF EXISTS (select * from [?].sys.fulltext_indexes where is_enabled=1) BEGIN PRINT ''======== DatabaseName: ?'' SELECT /*Object_name(fti.object_id) AS ''TableName''*/ sobj.name as [TableName], cat.name AS [CatalogName],
CAST(fti.is_enabled AS bit) AS [IsEnabled],
OBJECTPROPERTY(fti.object_id,''TableFullTextPopulateStatus'') AS [PopulationStatus],
(case change_tracking_state when ''M'' then 1 when ''A'' then 2 else 0 end) AS [ChangeTracking],
OBJECTPROPERTY(fti.object_id,''TableFullTextItemCount'') AS [ItemCount],
OBJECTPROPERTY(fti.object_id,''TableFullTextDocsProcessed'') AS [DocumentsProcessed],
OBJECTPROPERTY(fti.object_id,''TableFullTextPendingChanges'') AS [PendingChanges],
OBJECTPROPERTY(fti.object_id,''TableFullTextFailCount'') AS [NumberOfFailures],
si.name AS [UniqueIndexName]
FROM [?].sys.tables AS tbl
INNER JOIN [?].sys.fulltext_indexes AS fti ON fti.object_id=tbl.object_id
INNER JOIN [?].sys.fulltext_catalogs AS cat ON cat.fulltext_catalog_id = fti.fulltext_catalog_id
INNER JOIN [?].sys.indexes AS si ON si.index_id=fti.unique_index_id and si.object_id=fti.object_id
INNER JOIN [?].sys.sysobjects as sobj ON fti.object_id=sobj.id
PRINT '''' END'

GO

PRINT ''
PRINT '******** Full-text Column Information (for each FTEnabled column in a table)********'
PRINT '************************************************************************************'
PRINT ''
GO

sp_msforeachdb 'IF EXISTS (select * from [?].sys.fulltext_index_columns) BEGIN PRINT ''======== DatabaseName: ?'' SELECT col.name AS [ColumnName], /*object_name(icol.object_id)*/ sobj.name AS [TableName]
FROM [?].sys.tables AS tbl
INNER JOIN [?].sys.fulltext_indexes AS fti ON fti.object_id=tbl.object_id
INNER JOIN [?].sys.fulltext_index_columns AS icol ON icol.object_id=fti.object_id
INNER JOIN [?].sys.columns AS col ON col.object_id = icol.object_id and col.column_id = icol.column_id
INNER JOIN [?].sys.sysobjects as sobj ON icol.object_id=sobj.id
PRINT '''' END'
GO

PRINT ''
PRINT '******** WordBreaking Language Information ********'
PRINT '***************************************************'
PRINT ''
GO

sp_msforeachdb 'IF EXISTS (select * from [?].sys.fulltext_indexes where is_enabled=1) BEGIN PRINT ''======== DatabaseName: ?'' SELECT tbl.object_id as [ObjectID], tbl.name as [TableName], col.name AS [ColumnName], sl.name AS [WordBreaker_Language], sl.lcid AS [LCID]
FROM [?].sys.tables AS tbl
INNER JOIN [?].sys.fulltext_indexes AS fti ON fti.object_id=tbl.object_id
INNER JOIN [?].sys.fulltext_index_columns AS icol ON icol.object_id=fti.object_id
INNER JOIN [?].sys.columns AS col ON col.object_id = icol.object_id and col.column_id = icol.column_id
INNER JOIN [?].sys.fulltext_languages AS sl ON sl.lcid=icol.language_id
PRINT '''' END'

GO

PRINT ''
PRINT '******** IFilters loaded in SQL Server ********'
PRINT '***********************************************'
PRINT ''

select document_type as [Extension], manufacturer, version, path, Class_ID from sys.fulltext_document_types

GO
PRINT ''
PRINT '******** NON-Microsoft IFilters ********'
PRINT '****************************************'
PRINT ''

declare @count int
set @count = (select count(*) from sys.fulltext_document_types where manufacturer not like 'Microsoft Corporation' and path not like '%offfilt%')
if(@count <> 0)
begin
select document_type as [Extension], manufacturer, version, path, Class_ID from sys.fulltext_document_types where manufacturer not like 'Microsoft Corporation' and path not like '%offfilt%' 
end
else
begin
print 'No Non-Microsoft filters loaded'
print ''
end

GO

PRINT ''
PRINT '******** StopLists & Stopwords Information ********'
PRINT '***************************************************'
PRINT ''

SET NOCOUNT ON
GO

declare @version table (PropertyName nvarchar(30) NOT NULL, PropertyValue nvarchar(100))
declare @count int
declare @execoutput nvarchar(1000)
Insert @version SELECT 'Version', CAST(serverproperty('ProductVersion') AS nvarchar(100))
select @count = count(PropertyValue) from @version where PropertyValue like '10.0%'
if(@count=1)
begin

declare @dbname nvarchar(100)
declare dbcursor cursor for select name from sys.databases where state = 0 and name not in ('master','model','msdb','tempdb')
open dbcursor
fetch next from dbcursor into @dbname
While @@FETCH_STATUS = 0
BEGIN
SET NOCOUNT ON



IF object_id('tempdb..#result') IS NOT NULL
begin
drop table #result
end
IF object_id('tempdb..#result2') IS NOT NULL
begin
drop table #result2
end

create table #result (res bigint)
create table #result2 (res bigint)
declare @stopcount int
declare @listcount int
declare @sql nvarchar(100)
declare @sql2 nvarchar(100)

set @sql = 'select COUNT(*) from [' +@dbname+ '].sys.fulltext_stoplists'
set @sql2 = 'select COUNT(*) from [' +@dbname+ '].sys.fulltext_stopwords'
--select @stopcount (select COUNT(*) from sys.fulltext_stoplists)
--select @listcount (select COUNT(*) from sys.fulltext_stopwords)

insert into #result exec (@sql)
insert into #result2 exec (@sql2)
if((select res from #result) = 0)

begin
print 'No StopLists for database: ' + @dbname
print ''
end

else
begin
set @sql = 'select stoplist_id,name from [' +@dbname+ '].sys.fulltext_stoplists'
print 'StopLists for Database: ' + @dbname
exec(@sql)
print ''
end

if((select res from #result2) = 0)
begin
print 'No StopWords for database: ' + @dbname
print ''
end
else
begin
set @sql2 = 'select * from [' +@dbname+ '].sys.fulltext_stopwords'
print 'StopWords for Database: ' + @dbname
exec (@sql2)

print ''
end
drop table #result
drop table #result2
FETCH NEXT FROM dbcursor into @dbname
END
CLOSE dbcursor
DEALLOCATE dbcursor
end

else
begin
print 'Stoplists/Stopwords feature not available in SQL Server 2005'
print ''
end

SET NOCOUNT OFF
GO
PRINT ''
PRINT 'End Time: ' + CONVERT (varchar(30), GETDATE(), 121)
GO
