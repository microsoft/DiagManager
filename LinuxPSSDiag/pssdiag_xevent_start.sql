-- File path should be $(XEFilePath)/ and then add the file name.
-- Cannot add $XEFilePath as currently Native Linux paths not supported, once they are we definitely can
ALTER EVENT SESSION [PSSDiag_XEvent] ON SERVER 
ADD TARGET package0.event_file(SET filename=N'/home/SureshKaVM/pssdiag/output/SKB-VMD-UBU_pssdiag_xevent.xel',max_file_size=(500),max_rollover_files=(50))
GO
ALTER EVENT SESSION [PSSDiag_XEvent] on server state = start
GO

