
SET NOCOUNT ON
GO
PRINT '---------------------------------------'
PRINT '---- linked_server_config.sql'
PRINT '----   $Revision: 1 $'
PRINT '----   $Date: 2003/10/16 13:27:05 $'
PRINT '---------------------------------------'
PRINT ''
PRINT 'Start Time: ' + CONVERT (varchar(30), GETDATE(), 121)
GO
sp_configure 'show advanced', 1
go
reconfigure with override
go
sp_configure 'xp_cmdshell', 1
go
reconfigure with override
go
PRINT ''
PRINT '==== SELECT GETDATE()'
SELECT GETDATE()
PRINT ''
PRINT ''
PRINT '==== SELECT @@version'
SELECT @@VERSION
GO
PRINT ''
PRINT '==== SQL Server name'
SELECT @@SERVERNAME
GO
PRINT ''
PRINT '==== Host (client) machine name'
SELECT HOST_NAME()
GO
PRINT ''
PRINT '==== sp_configure advanced'
EXEC sp_configure 'show advanced', 1
RECONFIGURE WITH OVERRIDE
GO
EXEC sp_configure
GO
PRINT ''
PRINT '==== Active Trace Flags'
DBCC TRACESTATUS(-1)
GO
PRINT ''
PRINT '==== sp_helpsort'
EXEC sp_helpsort
GO
PRINT '======== SQL commandline args'
EXEC master..xp_instance_regenumvalues 'HKEY_LOCAL_MACHINE', 
  'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\Parameters'
GO
PRINT '======== Default client netlib and server aliases'
EXEC master..xp_regenumvalues 'HKEY_LOCAL_MACHINE', 
  'Software\Microsoft\MSSQLServer\Client\ConnectTo'
EXEC master..xp_regenumvalues 'HKEY_LOCAL_MACHINE', 
  'Software\Microsoft\MSSQLServer\Client\SuperSocketNetLib'
GO
PRINT '======== MDAC version information'
EXEC master..xp_regenumvalues 'HKEY_LOCAL_MACHINE', 
  'Software\Microsoft\DataAccess'
GO
PRINT ''
PRINT '==== sp_helpserver'
EXEC master..sp_helpserver
GO
PRINT ''
PRINT '==== Linked server properties'
PRINT ''
PRINT '======== sp_helplinkedservers'
EXEC master..sp_linkedservers
PRINT ''
PRINT '======== sp_helplinkedsrvlogin'
EXEC master..sp_helplinkedsrvlogin
PRINT ''
PRINT '======== xp_enum_oledb_providers'
EXEC master..xp_enum_oledb_providers
PRINT ''
PRINT '======== OLEDB provider SQL registry properties'
DECLARE @sql70or80xp sysname
IF CHARINDEX ('7.00.', @@VERSION) = 0
  SET @sql70or80xp = 'master..xp_instance_'
ELSE
  SET @sql70or80xp = 'master..xp_'
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE name like '#providers%') DROP TABLE #providers 
CREATE TABLE #providers
  (prov_name varchar(255), parse_name varchar(255), prov_descr text)
INSERT INTO #providers 
EXEC master..xp_enum_oledb_providers
DECLARE @prov_name varchar(255)
DECLARE @regpath varchar(4000)
DECLARE curs INSENSITIVE CURSOR 
FOR SELECT prov_name FROM #providers
FOR READ ONLY
OPEN curs
FETCH NEXT FROM curs INTO @prov_name
WHILE (@@FETCH_STATUS = 0)
BEGIN
  PRINT ''
  PRINT '======== Registry properties for provider ' + @prov_name
  SET @regpath = 'Software\Microsoft\MSSQLServer\Providers\' + @prov_name
  EXEC ('EXEC ' + @sql70or80xp + 'regenumvalues ''HKEY_LOCAL_MACHINE'', ''' + @regpath + '''')
  FETCH NEXT FROM curs INTO @prov_name
END
CLOSE curs
DEALLOCATE curs
GO
PRINT '==== ODBC DSN info'
PRINT 'EXEC master.dbo.xp_cmdshell ''regedit /e %tmp%\odbc_pss.txt HKEY_LOCAL_MACHINE\SOFTWARE\ODBC'''
EXEC master.dbo.xp_cmdshell 'regedit /e %tmp%\odbc_pss.txt HKEY_LOCAL_MACHINE\SOFTWARE\ODBC'
PRINT 'EXEC master.dbo.xp_cmdshell ''dir  %tmp%\odbc_pss.txt '''
EXEC master.dbo.xp_cmdshell 'dir  %tmp%\odbc_pss.txt '
PRINT 'EXEC master.dbo.xp_cmdshell ''type %tmp%\odbc_pss.txt'''
EXEC master.dbo.xp_cmdshell 'type %tmp%\odbc_pss.txt'
PRINT 'EXEC master.dbo.xp_cmdshell ''del %tmp%\odbc_pss.txt'''
EXEC master.dbo.xp_cmdshell 'del %tmp%\odbc_pss.txt'
GO
PRINT ''
PRINT '==== SELECT GETDATE()'
SELECT GETDATE()

