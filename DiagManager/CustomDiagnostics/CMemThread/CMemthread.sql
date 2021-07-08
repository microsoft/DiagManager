CREATE EVENT SESSION [CMemthread] ON SERVER
ADD EVENT sqlos.wait_info(
ACTION(package0.callstack)
WHERE (([wait_type]=(189)) -- map_key value returned from pervious query must be entered for wait_type.
AND ([opcode]=(1))))
ADD TARGET package0.event_file(SET filename=N'CMemthread') – Data will be logged to the errorlog folder
WITH (MEMORY_PARTITION_MODE=PER_CPU)
GO
-- start the event session
alter event session CMemthread on server state = start
go