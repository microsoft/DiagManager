use tempdb
go
if object_id ('t') is not null 
	drop table t

go
create table t (c1 int)
go
set nocount on
while 1 =1 
begin

	begin tran 
	insert into t select 1
	waitfor delay '0:0:20'
	rollback
end
