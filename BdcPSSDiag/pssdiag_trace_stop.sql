-- this stored procedure is created from MSDiagprocs.sql
-- please make sure that script runs before launching this

EXEC tempdb.dbo.sp_trace13 'OFF',@AppName='SQLDIAG_Test_*',@TraceName='tsqltrace'