Print ''
Print ''
Print'Starting New connection check'
print 'Start Time: ' select getdate()
Print 'Query Results:'
Print ''

select name, status, category from master..sysdatabases where dbid = 1

if @@error<>0
begin
	RAISERROR("LooksAlive Batch Error", 11, 1)
	return
end

Print ''
Print ''
print 'End Time: ' select getdate()
EXIT (select 70000)