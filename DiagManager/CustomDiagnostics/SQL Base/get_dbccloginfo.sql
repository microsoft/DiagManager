set nocount on
PRINT 'DBCC LogInfo'
PRINT '---------'
PRINT '';

DECLARE @dbname nvarchar(128);
DECLARE Database_Cursor CURSOR FOR
SELECT name FROM MASTER.sys.sysdatabases

OPEN Database_Cursor;

FETCH NEXT FROM Database_Cursor into @dbname;

WHILE @@FETCH_STATUS = 0
	BEGIN

	PRINT '-- DATABASE: ' + @dbname + ' --';
	DBCC LOGINFO(@dbname);
	PRINT '';
	PRINT '';

	FETCH NEXT FROM Database_Cursor into @dbname;

	END;
CLOSE Database_Cursor;
DEALLOCATE Database_Cursor;