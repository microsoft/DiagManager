ALTER EVENT SESSION [PSSDiag_XEvent] ON SERVER 
ADD TARGET package0.event_file(SET filename=N'/var/opt/mssql/log/sqlcontainer80a_container_instance_pssdiag_xevent.xel',max_file_size=(500),max_rollover_files=(50))
GO
ALTER EVENT SESSION [PSSDiag_XEvent] on server state = start
GO

