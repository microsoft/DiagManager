set nocount on

-- script to dump out metadata about columnstore indexes built on disk based tables and in-memory tables
EXEC sp_MSforeachdb '
	declare @runtime datetime = getdate()

	use [?] 

	if exists (select 1 from sys.indexes where type in (5,6)) 
	begin 

		print ''-- sys.objects --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  o.* 
			from sys.objects o join sys.indexes i on (o.object_id = i.object_id) 
			where i.type in (5,6) 

		print ''-- sys.columns --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  c.* 
			from sys.columns c join sys.indexes i on (c.object_id = i.object_id) 
			where i.type in (5,6)

		print ''-- sys.indexes --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  i.* 
			from sys.indexes i where i.type in (5,6)

		print ''-- sys.index_columns --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  ic.* 
			from sys.index_columns ic join sys.indexes i on (ic.object_id = i.object_id) 
			where i.type in (5,6)

		print ''-- sys.partitions --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  p.* 
			from sys.partitions p join sys.indexes i on (p.object_id = i.object_id) 
			where i.type in (5,6)

		print ''-- sys.internal_partitions --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  ip.* 
			from sys.internal_partitions ip join sys.indexes i on (ip.object_id = i.object_id) 
			where i.type in (5,6)

	end 

'
-- script to dump out runtime stats about columnstore indexes built on disk based tables and in-memory tables
EXEC sp_MSforeachdb '
	declare @runtime datetime = getdate()

	use [?] 

	if exists (select 1 from sys.indexes where type in (5,6)) 
	begin 

		print ''-- sys.row_group_physical_stats --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  ps.* 
			from sys.dm_db_column_store_row_group_physical_stats ps

		print ''-- sys.row_group_operational_stats --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  os.* 
			from sys.dm_db_column_store_row_group_operational_stats os

		print ''-- sys.column_store_object_pool --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  op.* 
			from sys.dm_column_store_object_pool op

		print ''-- sys.column_store_dictionaries --'' 
		select convert (varchar(30), @runtime, 126) AS ''runtime'', 
			db_id() ''database_id'', db_name() ''database_name'' ,  csd.* 
			from sys.column_store_dictionaries csd

	end
'

-- this can be expensive, can add later based on usability
--select * from sys.dm_db_index_physical_stats(0,0,-1,0,DEFAULT) where columnstore_delete_buffer_state > 0     

-- script to dump out in-memory stats about columnstore indexes built on in-memory tables

EXEC sp_MSforeachdb '
	declare @runtime datetime = getdate()

	use [?] 

	if exists (select 1 from sys.tables t join sys.indexes i on (t.object_id = i.object_id) where i.type in (5,6) and t.is_memory_optimized = 1) 
	begin 

	print ''-- sys.memory_optimized_tables_internal_attributes --'' 
	select convert (varchar(30), @runtime, 126) AS ''runtime'', 
		db_id() ''database_id'', db_name() ''database_name'' ,  mia.* 
		from sys.memory_optimized_tables_internal_attributes mia join sys.indexes i on (mia.object_id = i.object_id) 
		where i.type in (5,6) 
	
	print ''-- sys.dm_db_xtp_table_memory_stats --'' 
	select convert (varchar(30), @runtime, 126) AS ''runtime'', 
		db_id() ''database_id'', db_name() ''database_name'' ,  ms.* 
		from sys.dm_db_xtp_table_memory_stats ms join sys.indexes i on (ms.object_id = i.object_id) 
		where i.type in (5,6)
	
	print ''-- sys.dm_db_xtp_memory_consumers --'' 
	select convert (varchar(30), @runtime, 126) AS ''runtime'', 
		db_id() ''database_id'', db_name() ''database_name'' ,  mc.* 
		from sys.dm_db_xtp_memory_consumers mc join sys.indexes i on (mc.object_id = i.object_id) 
		where i.type in (5,6)

	print ''-- sys.dm_db_xtp_checkpoint_files --'' 
	select convert (varchar(30), @runtime, 126) AS ''runtime'', 
		db_id() ''database_id'', db_name() ''database_name'' ,  cf.* 
		from sys.dm_db_xtp_checkpoint_files cf

	print ''-- sys.sys.dm_db_xtp_checkpoint_stats --'' 
	select convert (varchar(30), @runtime, 126) AS ''runtime'', 
		db_id() ''database_id'', db_name() ''database_name'' ,  cs.* 
		from sys.dm_db_xtp_checkpoint_stats cs

	end
'

