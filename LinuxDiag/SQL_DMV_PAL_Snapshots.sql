USE master
go

print ''
RAISERROR ('--PAL DMVs --', 0, 1) WITH NOWAIT

DECLARE @runtime datetime = GETDATE()
DECLARE @msg varchar(100)

SET @msg = 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
RAISERROR (@msg, 0, 1) WITH NOWAIT

print ''
RAISERROR ('--sys.dm_pal_cpu_stats--', 0, 1) WITH NOWAIT
select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_cpu_stats
go

DECLARE @runtime datetime = GETDATE()
print ''
RAISERROR ('--sys.dm_pal_disk_stats--', 0, 1) WITH NOWAIT
select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_disk_stats
go

DECLARE @runtime datetime = GETDATE()
print ''
RAISERROR ('--sys.dm_pal_net_stats--', 0, 1) WITH NOWAIT
select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_net_stats
go

DECLARE @runtime datetime = GETDATE()
print ''
RAISERROR ('--sys.dm_pal_processes--', 0, 1) WITH NOWAIT
select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_processes
go

DECLARE @runtime datetime = GETDATE()
print ''
RAISERROR ('--sys.dm_pal_vm_stats--', 0, 1) WITH NOWAIT
select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_vm_stats
go

--DECLARE @runtime datetime = GETDATE()
--print ''
--RAISERROR ('--sys.dm_pal_wait_stats--', 0, 1) WITH NOWAIT
--select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_wait_stats
--go

--DECLARE @runtime datetime = GETDATE()
--print ''
--#RAISERROR ('--sys.dm_pal_spinlock_stats--', 0, 1) WITH NOWAIT
--select CONVERT (varchar(30), @runtime, 126) AS 'runtime', * from sys.dm_pal_spinlock_stats
--go