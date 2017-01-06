select @@servername as server, convert(varchar(26), getdate(), 121) as [date],3 as [version]
go
print '-- SQL Server service startup account'
EXEC master.dbo.xp_instance_regread  'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\Services\MSSQLServer', 'ObjectName'
go
print '-- sys.database_mirroring'
select * from sys.database_mirroring where mirroring_guid is not null
go
print '-- sys.database_mirroring_witnesses'
select * from sys.database_mirroring_witnesses
go
if exists (select * from sys.database_mirroring_endpoints where connection_auth = 4)
begin
print '-- Endpoint Owner and Information using Certificates'
select c.string_sid,c.certificate_id, c.name, c.principal_id, c.pvt_key_encryption_type_desc,
 'date valid cert'=case when getdate() between c.start_date and c.expiry_date then 1 else 0 end,
 c.start_date, c.expiry_date,
 dme.name, dme.endpoint_id, dme.role_desc, dme.connection_auth_desc, dme.encryption_algorithm_desc,
 sp.name, sp.type_desc,
 te.principal_id, te.state_desc, te.port, te.ip_address 
from sys.database_mirroring_endpoints dme inner join sys.tcp_endpoints te on dme.endpoint_id = te.endpoint_id
inner join sys.server_principals sp on sp.principal_id = dme.principal_id
inner join sys.certificates c on c.certificate_id = dme.certificate_id
print '-- Granted permissions on Endpoint using Certificates'
select c.string_sid,c.certificate_id, c.name, c.principal_id, c.pvt_key_encryption_type_desc,
 'date valid cert'=case when getdate() between c.start_date and c.expiry_date then 1 else 0 end,
 c.start_date, c.expiry_date, 
 dp.name, dp.type_desc, sp.grantee_principal_id, spee.name, spee.type_desc, 
 sp.grantor_principal_id, sp.permission_name, sp.state_desc
 from sys.server_permissions sp inner join sys.database_mirroring_endpoints dme on sp.major_id = dme.endpoint_id
 inner join sys.server_principals spee on sp.grantee_principal_id = spee.principal_id
 inner join master.sys.database_principals dp on spee.sid = dp.sid
 inner join sys.certificates c on c.principal_id = dp.principal_id
end
else
begin
print '-- Endpoint Owner and Information NOT using Certificates'
select  te.state_desc, te.port, te.ip_address, dme.name, dme.endpoint_id, dme.role_desc, dme.connection_auth_desc, dme.encryption_algorithm_desc,
  sp.principal_id, sp.name from sys.server_principals sp
 inner join sys.database_mirroring_endpoints dme on sp.principal_id = dme.principal_id
 inner join sys.tcp_endpoints te on dme.endpoint_id = te.endpoint_id
print '-- Granted permissions on Endpoint NOT using Certificates'
select  sp.grantee_principal_id, spee.name, spee.type_desc, 
 sp.grantor_principal_id, spor.name, spor.type_desc,
 sp.permission_name, sp.state_desc,  dme.endpoint_id
 from sys.server_permissions sp right outer join sys.database_mirroring_endpoints dme on sp.major_id = dme.endpoint_id
 inner join sys.server_principals spee on sp.grantee_principal_id = spee.principal_id
 inner join sys.server_principals spor on sp.grantor_principal_id = spor.principal_id
end
go
print '-- sys.database_recovery_status'
select 'dbname'=db_name(rs.database_id), rs.* from sys.database_recovery_status rs
inner join sys.database_mirroring m on rs.database_id = m.database_id and m.mirroring_guid is not null
go
print '-- sys.databases (log_reuse_wait_info)'
select 'dbname'=db_name(d.database_id), d.database_id, d.log_reuse_wait, d.log_reuse_wait_desc from sys.databases d
inner join sys.database_mirroring m on d.database_id = m.database_id and m.mirroring_guid is not null
go
print '-- log backups for mirroring databases'
select b.* from msdb.dbo.backupset b
inner join sys.database_mirroring m on b.database_name = db_name(m.database_id) and m.mirroring_guid is not null
where type = 'L' 
order by backup_finish_date desc
go
print '-- dbcc tracestatus (-1)'
dbcc tracestatus(-1)
go
dbcc traceon (3604,1495,-1)
go
declare @dbid varchar(30)
declare @dbname nvarchar(128)
declare @status sql_variant
declare @useraccess sql_variant
declare c cursor for select database_id from sys.database_mirroring where mirroring_guid is not null
open c
fetch next from c into @dbid
while (@@fetch_status <> -1)
begin
  print '===================================================='
  print '-- DBCC DBTABLE (' + @dbid + ')'
  exec ('dbcc dbtable (' + @dbid + ')')
  print ''
  set @dbname = db_name(@dbid)
  set @status = DATABASEPROPERTYEX(@dbname,'Status')
  set @useraccess = DATABASEPROPERTYEX(@dbname,'UserAccess')
  print '===================================================='
  print '-- DBCC OPENTRAN FOR DBID ' + @dbid + ' ['+ @dbname + ']'
  if @Status = N'ONLINE' and @UserAccess != N'SINGLE_USER'
    dbcc opentran(@dbname)
  else
    print 'Skipped: Status=' + convert(nvarchar(128),@status)
      + ' UserAccess=' + convert(nvarchar(128),@useraccess)
  fetch next from c into @dbid
end
close c
deallocate c
print '===================================================='
print '-- DBCC RESOURCE'
DBCC RESOURCE
go
dbcc traceoff (3604,1495,-1)
go
print '-- IPCONFIG /ALL'
exec master.dbo.xp_cmdshell 'ipconfig /all'
go
