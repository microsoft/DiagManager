DECLARE @name sysname
DECLARE @sqlstr nvarchar(max)
DECLARE mycursor cursor for 
select name from sys.dm_xe_sessions
where name like 'pssdiag_xevent%'


OPEN mycursor   
FETCH NEXT FROM mycursor INTO @name   
WHILE @@FETCH_STATUS = 0   
BEGIN   
set @sqlstr = 'ALTER EVENT SESSION [' + @name + '] ON SERVER STATE = STOP'
exec (@sqlstr)
FETCH NEXT FROM mycursor INTO @name   
END
CLOSE mycursor
DEALLOCATE mycursor 
