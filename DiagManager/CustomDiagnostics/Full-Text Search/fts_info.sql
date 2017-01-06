PRINT '---------------------------------------'
PRINT '---- fts_info.sql'
PRINT '----   $Revision: 1 $'
PRINT '----   $Date: 2003/10/16 13:27:05 $'
PRINT '---------------------------------------'
PRINT ''
PRINT 'Start Time: ' + CONVERT (varchar(30), GETDATE(), 121)
GO
DECLARE @IsFullTextInstalled int
PRINT '==== Full-text information'
PRINT '======== FULLTEXTSERVICEPROPERTY (IsFulltextInstalled)'
SET @IsFullTextInstalled = FULLTEXTSERVICEPROPERTY ('IsFulltextInstalled')
PRINT CASE @IsFullTextInstalled 
    WHEN 1 THEN '1 - Yes' 
    WHEN 0 THEN '0 - No' 
    ELSE 'Unknown'
  END
IF (@IsFullTextInstalled = 1)
BEGIN
  PRINT '======== FULLTEXTSERVICEPROPERTY (ResourceUsage)'
  PRINT CASE FULLTEXTSERVICEPROPERTY ('ResourceUsage')
      WHEN 0 THEN '0 - MSSearch not running'
      WHEN 1 THEN '1 - Background'
      WHEN 2 THEN '2 - Low'
      WHEN 3 THEN '3 - Normal'
      WHEN 4 THEN '4 - High'
      WHEN 5 THEN '5 - Highest'
      ELSE CONVERT (varchar, FULLTEXTSERVICEPROPERTY ('ResourceUsage'))
    END

  PRINT '======== FULLTEXTSERVICEPROPERTY (ConnectTimeout)'
  PRINT CONVERT (varchar, FULLTEXTSERVICEPROPERTY ('ConnectTimeout')) + ' sec'
  PRINT ''

  DECLARE @dbn varchar(31)
  DECLARE @cm varchar(8000)
  DECLARE db_cursor CURSOR FOR
  SELECT name FROM master.dbo.sysdatabases WHERE DATABASEPROPERTY (name, 'IsFulltextEnabled') = 1
  FOR READ ONLY
  IF 0 = @@ERROR
  BEGIN
    OPEN db_cursor
    IF 0 = @@ERROR
    BEGIN
      FETCH db_cursor INTO @dbn
      WHILE @@FETCH_STATUS <> -1 AND 0 = @@ERROR
      BEGIN
        SELECT @cm = '
USE ' + + @dbn + '
PRINT ''======== sp_help_fulltext_catalogs''
EXEC sp_help_fulltext_catalogs
PRINT ''======== sp_help_fulltext_tables''
EXEC sp_help_fulltext_tables
PRINT ''======== sp_help_fulltext_columns''
EXEC sp_help_fulltext_columns
PRINT ''======== Catalog properties''
SELECT name, FULLTEXTCATALOGPROPERTY (name, ''ItemCount'') AS ItemCount, 
  CONVERT (varchar, FULLTEXTCATALOGPROPERTY (name, ''IndexSize'')) + ''MB'' AS IndexSize, 
  FULLTEXTCATALOGPROPERTY (name, ''UniqueKeyCount'') AS UniqueKeyCount
FROM sysfulltextcatalogs 
USE master'
        PRINT '======== Full text information for db [' + @dbn + ']'
        EXEC(@cm)
        FETCH db_cursor INTO @dbn
      END
      CLOSE db_cursor
    END
    DEALLOCATE db_cursor
  END
END
PRINT ''
GO


if @@microsoftversion >=134217922
begin
	
	set nocount on
	print 'server wide info'
	select @@servername as 'server name'
	select @@version
	
	print 'MaxPropStoreCachedSize'
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Search\1.0\Indexer', N'MaxPropStoreCachedSize'
	
	print 'some server properties'
	
		select 	convert(int, serverproperty(N'isclustered')) as 'Is server clustered', 
				convert(varchar, serverproperty(N'Edition') ) as 'Server edition',
				convert (varchar, serverproperty(N'LicenseType')) as  'LicenseType',
				cast (serverproperty(N'NumLicenses') as varchar) 'NumLicenses',
				cast (serverproperty(N'Collation') as varchar) 'Collation',
				cast (serverproperty(N'InstanceName') as varchar) as 'instance name'
	
	
	print '*******************************'
	print 'SQL Server start account'
	
	declare @instancename nvarchar (128), @key nvarchar(1000)
	set @instancename = cast ( serverproperty(N'InstanceName') as nvarchar)
	if @instancename  is not null
			set @key='System\CurrentControlSet\Services\MSSQL$'+@instancename
	else 
		set @key='System\CurrentControlSet\Services\MSSQLServer'	
	
	
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', 
	@key,  N'ObjectName'
	print 'SQL Server Agent startup account'
	--declare @instancename nvarchar (128), @key nvarchar(1000)
	set @instancename = cast ( serverproperty(N'InstanceName') as nvarchar)
	if @instancename  is not null
	begin
		set @key='System\CurrentControlSet\Services\SQLAgent$'+@instancename
	end
	else 
	begin
		set @key='System\CurrentControlSet\Services\SQLServerAgent'	
	end
	
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', 
	@key,  N'ObjectName'
	
	
	print 'MSSEARCh startup account'
	exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', 
		'System\CurrentControlSet\Services\MSSearch',
		N'ObjectName'
	
	print ''
	print '*************************'
	print 'sysadmin member'
	print '==============='
	exec sp_helpsrvrolemember
	
	print ''
	print 'local adminstrators group memeber'
	exec master.dbo.xp_cmdshell 'net localgroup Administrators'
	
	
	print '***********************'
	print 'Full Text Default Path'
	--declare @instancename nvarchar (128), @key nvarchar(1000)
	declare @path nvarchar(2000)
	set @instancename = cast ( serverproperty(N'InstanceName') as nvarchar)
	if @instancename  is not null
	begin
		set @key='Software\Microsoft\Microsoft SQL Server\'+@instancename +'\MSSQLServer'
	end
	else 
	begin
		set @key='Software\Microsoft\MSSQLServer\MSSQLServer'		
	end
	
	create table #fulltextpath (value Nvarchar(2000), data nvarchar(2000))
	
	insert into #fulltextpath exec master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', 
	@key,  N'FullTextDefaultPath'
	
	declare @fulltextpath nvarchar(2000)
	select top 1 @fulltextpath=data from #fulltextpath
	drop table #fulltextpath
	print 'default fulltext path ' + @fulltextpath
	print 'permissions on default fulltext path'
	declare @cmd nvarchar(2000)
	set @cmd = 'cacls "' + @fulltextpath + '"'
	exec master.dbo.xp_cmdshell @cmd
	set @cmd = 'cacls ' + substring (@fulltextpath,1,3)
	print 'permissions on the root dir of default full text path'
	exec master.dbo.xp_cmdshell @cmd
	
	print 'services started'
	exec master.dbo.xp_cmdshell 'net start'
end
else
begin
	print 'Some information was not collected because the SQL Server version was prior to SQL 2000 RTM'
end




