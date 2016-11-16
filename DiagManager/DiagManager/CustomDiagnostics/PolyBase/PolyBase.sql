RAISERROR ('--sys.external_tables--', 0, 1) WITH NOWAIT
select * from sys.external_tables 
RAISERROR ('  ', 0, 1) WITH NOWAIT



RAISERROR ('--sys.external_data_sources--', 0, 1) WITH NOWAIT
select * from sys.external_data_sources 
RAISERROR ('  ', 0, 1) WITH NOWAIT


RAISERROR ('--sys.external_file_formats--', 0, 1) WITH NOWAIT
select * from sys.external_file_formats 
RAISERROR ('  ', 0, 1) WITH NOWAIT



RAISERROR ('--sys.dm_exec_compute_node_errors--', 0, 1) WITH NOWAIT
select * from sys.dm_exec_compute_node_errors  
RAISERROR ('  ', 0, 1) WITH NOWAIT


RAISERROR ('--sys.dm_exec_compute_node_status--', 0, 1) WITH NOWAIT
select * from sys.dm_exec_compute_node_status  
RAISERROR ('  ', 0, 1) WITH NOWAIT

RAISERROR ('--sys.dm_exec_compute_nodes--', 0, 1) WITH NOWAIT
select * from sys.dm_exec_compute_nodes  
RAISERROR ('  ', 0, 1) WITH NOWAIT

RAISERROR ('--sys.dm_exec_distributed_request_steps--', 0, 1) WITH NOWAIT
select * from sys.dm_exec_distributed_request_steps  
RAISERROR ('  ', 0, 1) WITH NOWAIT

RAISERROR ('--sys.dm_exec_distributed_requests--', 0, 1) WITH NOWAIT
select * from sys.dm_exec_distributed_requests  
RAISERROR ('  ', 0, 1) WITH NOWAIT

RAISERROR ('--sys.dm_exec_distributed_sql_requests--', 0, 1) WITH NOWAIT
select * from sys.dm_exec_distributed_sql_requests  
RAISERROR ('  ', 0, 1) WITH NOWAIT

RAISERROR ('--sys.dm_exec_dms_services--', 0, 1) WITH NOWAIT
select * from sys.dm_exec_dms_services  
RAISERROR ('  ', 0, 1) WITH NOWAIT

RAISERROR ('--sys.dm_exec_dms_workers  --', 0, 1) WITH NOWAIT
select * from sys.dm_exec_dms_workers  
RAISERROR ('  ', 0, 1) WITH NOWAIT

RAISERROR ('--sys.dm_exec_external_operations--', 0, 1) WITH NOWAIT
select * from sys.dm_exec_external_operations  
RAISERROR ('  ', 0, 1) WITH NOWAIT

RAISERROR ('--sys.dm_exec_external_work--', 0, 1) WITH NOWAIT
select * from sys.dm_exec_external_work  
RAISERROR ('  ', 0, 1) WITH NOWAIT
