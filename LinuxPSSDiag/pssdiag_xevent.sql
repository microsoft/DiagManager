-- Enter all the XE's to be collectoed, Prefixed by PSSDIAG_XEvent

if exists (select * from sys.server_event_sessions  where name = 'PSSDiag_XEvent')
	DROP EVENT SESSION [PSSDiag_XEvent] ON SERVER 
go

-- File path should be $(XEFilePath)/ and then add the file name.
-- Cannot add $XEFilePath as currently Native Linux paths not supported, once they are we definitely can
CREATE EVENT SESSION [PSSDiag_XEvent] ON SERVER 
ADD EVENT sqlserver.rpc_completed(SET collect_data_stream=(1),collect_statement=(1)
    ACTION(package0.collect_cpu_cycle_time,package0.collect_current_thread_id,package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.query_hash,sqlserver.request_id,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(package0.collect_current_thread_id,package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.query_hash,sqlserver.request_id,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.session_server_principal_name,sqlserver.sql_text,sqlserver.transaction_id,sqlserver.username)) 
WITH (MAX_MEMORY=200800 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=10 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=PER_CPU,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

