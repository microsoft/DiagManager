use tempdb
go
if object_id ('usp_Hekaton_Server_Collector') is not null
	drop procedure usp_Hekaton_Server_Collector

go


create procedure usp_Hekaton_Server_Collector @runtime datetime
as
RAISERROR ('  ', 0, 1) WITH NOWAIT 
RAISERROR ('--sys.dm_xtp_system_memory_consumers --', 0, 1) WITH NOWAIT
select  @runtime 'runtime', * from sys.dm_xtp_system_memory_consumers  
RAISERROR ('  ', 0, 1) WITH NOWAIT 

RAISERROR ('--sys.dm_xtp_gc_queue_stats --', 0, 1) WITH NOWAIT
select  @runtime 'runtime', * from sys.dm_xtp_gc_queue_stats  
RAISERROR ('  ', 0, 1) WITH NOWAIT 

RAISERROR ('--sys.dm_xtp_gc_stats --', 0, 1) WITH NOWAIT
select  @runtime 'runtime', * from sys.dm_xtp_gc_stats  
RAISERROR ('  ', 0, 1) WITH NOWAIT 

go


if object_id ('usp_Hekaton_Database_Collector') is not null
	drop procedure usp_Hekaton_Database_Collector

go


create procedure usp_Hekaton_Database_Collector @runtime datetime, @Database_Name sysname
as
declare @sql nvarchar(max) 

RAISERROR ('  ', 0, 1) WITH NOWAIT 

set @sql = N'use [' + @Database_name + '] select @runtime ''runtime'',  db_name() ''database_name'', * from sys.dm_db_xtp_table_memory_stats '
RAISERROR ('--sys.dm_db_xtp_table_memory_stats --', 0, 1) WITH NOWAIT 
exec sp_executesql @sql, N'@runtime datetime', @runtime
RAISERROR ('  ', 0, 1) WITH NOWAIT 

go



while 1 = 1
begin
	declare @runtime datetime
	set @runtime = getdate()

	exec usp_Hekaton_Server_Collector @runtime 
	declare @dbname sysname
	declare dbCURSOR CURSOR for select name from sys.databases where state_desc='ONLINE' and user_access_desc='MULTI_USER'
	open dbCURSOR
	fetch next from dbCursor into @dbname 
	while @@FETCH_STATUS = 0
			begin
			declare @HasHekatonTable int
			declare @cmd nvarchar(max) =N'select @HasHekatonTable = count (*) from [' + @dbname + N'].sys.tables where is_memory_optimized = 1'
			exec sp_executesql @cmd, N'@HasHekatonTable Int output', @HasHekatonTable output
			--only get property for databases that have 
			if @HasHekatonTable >0
				begin
					exec usp_Hekaton_Database_Collector @runtime, @dbname
				end
			fetch next from dbCursor into @dbname 
			end
	close dbCURSOR
	deallocate dbCURSOR
	waitfor delay '00:00:20'

end 








