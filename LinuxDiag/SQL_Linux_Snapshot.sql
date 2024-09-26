USE tempdb
GO
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET NUMERIC_ROUNDABORT OFF
GO

/*******************************************************************
perf stats snapshot

********************************************************************/
use tempdb
go
IF OBJECT_ID ('#sp_Linux_Snapshot','P') IS NOT NULL
   DROP PROCEDURE #sp_Linux_Snapshot
GO

CREATE PROCEDURE #sp_Linux_Snapshot  
as
begin
	BEGIN TRY

		PRINT 'Starting SQL Server Linux Snapshot Script...'
		PRINT 'SQL Version (SP)         ' + CONVERT (varchar, SERVERPROPERTY ('ProductVersion')) + ' (' + CONVERT (varchar, SERVERPROPERTY ('ProductLevel')) + ')'
		DECLARE @runtime datetime 
		DECLARE @cpu_time_start bigint, @cpu_time bigint, @elapsed_time_start bigint, @rowcount bigint
		DECLARE @queryduration int, @qrydurationwarnthreshold int
		DECLARE @querystarttime datetime
		SET @runtime = GETDATE()
		SET @qrydurationwarnthreshold = 5000
		
		PRINT ''
		PRINT 'Start time: ' + CONVERT (varchar(30), @runtime, 126)
		PRINT ''

		-- PRINT '--  --'
		-- SELECT @cpu_time_start = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID
		-- SET @querystarttime = GETDATE()

		-- --//main query

		-- SET @rowcount = @@ROWCOUNT
		-- SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
		-- IF @queryduration > @qrydurationwarnthreshold
		-- BEGIN
		-- SELECT @cpu_time = cpu_time - @cpu_time_start FROM sys.dm_exec_sessions WHERE session_id = @@SPID
		-- PRINT ''
		-- PRINT 'DebugPrint: Linux_snapshot_querystats - ' + CONVERT (varchar, @queryduration) + 'ms, ' 
		-- 	+ CONVERT (varchar, @cpu_time) + 'ms cpu, '
		-- 	+ 'rowcount=' + CONVERT(varchar, @rowcount) 
		-- PRINT ''
		-- END


		PRINT ''
    	RAISERROR ('-- dm_os_ring_buffers --', 0, 1) WITH NOWAIT;
    	SET @querystarttime = GETDATE()

		SELECT 
		DATEADD(ms, - 1 * (inf.ms_ticks - ring.timestamp), GETDATE()) AS ring_buffer_record_time,
		record
		FROM sys.dm_os_ring_buffers ring
		CROSS JOIN sys.dm_os_sys_info inf
		WHERE ring_buffer_type in ('RING_BUFFER_CONNECTIVITY','RING_BUFFER_SECURITY_ERROR')

		SET @rowcount = @@ROWCOUNT
		SET @queryduration = DATEDIFF (ms, @querystarttime, GETDATE())
		IF @queryduration > @qrydurationwarnthreshold
		BEGIN
		SELECT @cpu_time = cpu_time - @cpu_time_start FROM sys.dm_exec_sessions WHERE session_id = @@SPID
		PRINT ''
		PRINT 'DebugPrint: Linux_snapshot_querystats - ' + CONVERT (varchar, @queryduration) + 'ms, ' 
			+ CONVERT (varchar, @cpu_time) + 'ms cpu, '
			+ 'rowcount=' + CONVERT(varchar, @rowcount) 
		PRINT ''
		END


		PRINT ''
		PRINT '==== RING_BUFFER_CONNECTIVITY - LOGIN TIMERS'

		SELECT a.* FROM
		(SELECT 
		x.value('(//Record/ConnectivityTraceRecord/RecordTime)[1]', 'nvarchar(30)') AS [RecordTime],
		x.value('(//Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(30)') AS [RecordType], 
		x.value('(//Record/ConnectivityTraceRecord/Spid)[1]', 'int') AS [Spid], 
		x.value('(//Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'int') AS [SniConsumerError], 
		x.value('(//Record/ConnectivityTraceRecord/State)[1]', 'int') AS [State], 
		x.value('(//Record/ConnectivityTraceRecord/LocalPort)[1]', 'bigint') AS [LocalPort],
		x.value('(//Record/ConnectivityTraceRecord/RemoteHost)[1]', 'nvarchar(30)') AS [RemoteHost],
		x.value('(//Record/ConnectivityTraceRecord/RemotePort)[1]', 'bigint') AS [RemotePort],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/TotalTime)[1]', 'int') AS [TotalLoginTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/EnqueueTime)[1]', 'int') AS [EnqueueTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/NetWritesTime)[1]', 'int') AS [NetworkWritesInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/NetReadsTime)[1]', 'int') AS [NetworkReadsInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Ssl/TotalTime)[1]', 'int') AS [SslTotalTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Ssl/NetReadsTime)[1]', 'int') AS [SslNetReadsTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Ssl/NetWritesTime)[1]', 'int') AS [SslNetWritesTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Ssl/SecAPITime)[1]', 'int') AS [SslSecAPITimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Ssl/EnqueueTime)[1]', 'int') AS [SslEnqueueTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Sspi/TotalTime)[1]', 'int') AS [SspiTotalTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Sspi/NetReadsTime)[1]', 'int') AS [SspiNetReadsTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Sspi/NetWritesTime)[1]', 'int') AS [SspiNetWritesTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Sspi/SecAPITime)[1]', 'int') AS [SspiSecAPITimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Sspi/EnqueueTime)[1]', 'int') AS [SspiEnqueueTimeInMilliseconds],
		x.value('(//Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/TriggerAndResGovTime)[1]', 'int') AS [TriggerAndResGovTimeInMilliseconds]
		FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers 
		WHERE ring_buffer_type = 'RING_BUFFER_CONNECTIVITY') AS R(x)) a
		where a.RecordType = 'LoginTimers'
		order by a.recordtime 
		
		PRINT ''
		PRINT ''
		PRINT '==== RING_BUFFER_CONNECTIVITY - TDS Data - Error'

		SELECT a.* FROM
		(SELECT 
		x.value('(//Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(30)') AS [RecordType], 
		x.value('(//Record/ConnectivityTraceRecord/RecordSource)[1]', 'varchar(30)') AS [RecordSource], 
		x.value('(//Record/ConnectivityTraceRecord/LocalPort)[1]', 'bigint') AS [LocalPort],
		x.value('(//Record/ConnectivityTraceRecord/RemoteHost)[1]', 'nvarchar(30)') AS [RemoteHost],
		x.value('(//Record/ConnectivityTraceRecord/RemotePort)[1]', 'bigint') AS [RemotePort],
		x.value('(//Record/ConnectivityTraceRecord/Spid)[1]', 'int') AS [Spid], 
		x.value('(//Record/ConnectivityTraceRecord/OSError)[1]', 'int') AS [OSError], 
		x.value('(//Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'int') AS [SniConsumerError], 
		x.value('(//Record/ConnectivityTraceRecord/State)[1]', 'int') AS [State], 
		x.value('(//Record/ConnectivityTraceRecord/RecordTime)[1]', 'nvarchar(30)') AS [RecordTime],
		x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferError)[1]', 'int') AS [TdsInputBufferError],
		x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsOutputBufferError)[1]', 'int') AS [TdsOutputBufferError],
		x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferBytes)[1]', 'int') AS [TdsInputBufferBytes],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/PhysicalConnectionIsKilled)[1]', 'int') AS [PhysicalConnectionIsKilled],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/DisconnectDueToReadError)[1]', 'int') AS [DisconnectDueToReadError],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NetworkErrorFoundInInputStream)[1]', 'int') AS [NetworkErrorFoundInInputStream],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/ErrorFoundBeforeLogin)[1]', 'int') AS [ErrorFoundBeforeLogin],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/SessionIsKilled)[1]', 'int') AS [SessionIsKilled],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalDisconnect)[1]', 'int') AS [NormalDisconnect]
		FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers 
		WHERE ring_buffer_type = 'RING_BUFFER_CONNECTIVITY') AS R(x)) a
		where a.RecordType = 'Error'
		order by a.recordtime

		PRINT ''
		PRINT ''
		PRINT '==== RING_BUFFER_CONNECTIVITY - TDS Data - ConnectionClose'

		SELECT a.* FROM
		(SELECT 
		x.value('(//Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(30)') AS [RecordType], 
		x.value('(//Record/ConnectivityTraceRecord/RecordSource)[1]', 'varchar(30)') AS [RecordSource], 
		x.value('(//Record/ConnectivityTraceRecord/LocalPort)[1]', 'bigint') AS [LocalPort],
		x.value('(//Record/ConnectivityTraceRecord/RemoteHost)[1]', 'nvarchar(30)') AS [RemoteHost],
		x.value('(//Record/ConnectivityTraceRecord/RemotePort)[1]', 'bigint') AS [RemotePort],
		x.value('(//Record/ConnectivityTraceRecord/Spid)[1]', 'int') AS [Spid], 
		x.value('(//Record/ConnectivityTraceRecord/RecordTime)[1]', 'nvarchar(30)') AS [RecordTime],
		x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferError)[1]', 'int') AS [TdsInputBufferError],
		x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsOutputBufferError)[1]', 'int') AS [TdsOutputBufferError],
		x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferBytes)[1]', 'int') AS [TdsInputBufferBytes],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/PhysicalConnectionIsKilled)[1]', 'int') AS [PhysicalConnectionIsKilled],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/DisconnectDueToReadError)[1]', 'int') AS [DisconnectDueToReadError],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NetworkErrorFoundInInputStream)[1]', 'int') AS [NetworkErrorFoundInInputStream],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/ErrorFoundBeforeLogin)[1]', 'int') AS [ErrorFoundBeforeLogin],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/SessionIsKilled)[1]', 'int') AS [SessionIsKilled],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalDisconnect)[1]', 'int') AS [NormalDisconnect],
		x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalLogout)[1]', 'int') AS [NormalLogout]
		FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers 
		WHERE ring_buffer_type = 'RING_BUFFER_CONNECTIVITY') AS R(x)) a
		where a.RecordType = 'ConnectionClose'
		order by a.recordtime


		PRINT ''
		PRINT ''
		PRINT '==== RING_BUFFER_SECURITY_ERRROR'

		SELECT 
		dateadd (ms, rbf.[timestamp] - tme.ms_ticks, GETDATE()) as [Notification_Time],
		cast(record as xml).value('(//SPID)[1]', 'bigint') as SPID,
		cast(record as xml).value('(//ErrorCode)[1]', 'varchar(255)') as Error_Code,
		cast(record as xml).value('(//CallingAPIName)[1]', 'varchar(255)') as [CallingAPIName],
		cast(record as xml).value('(//APIName)[1]', 'varchar(255)') as [APIName],
		cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],
		cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type],
		cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time],tme.ms_ticks as [Current Time]
		from sys.dm_os_ring_buffers rbf
		cross join sys.dm_os_sys_info tme
		where rbf.ring_buffer_type = 'RING_BUFFER_SECURITY_ERROR'
		ORDER BY rbf.timestamp ASC

		PRINT ''
		PRINT ''
		PRINT '==== RING_BUFFER_EXCEPTION'

		SELECT 
		dateadd (ms, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) as Time_Stamp,
		cast(record as xml).value('(//Exception//Error)[1]', 'varchar(255)') as [Error],
		cast(record as xml).value('(//Exception/Severity)[1]', 'varchar(255)') as [Severity],
		cast(record as xml).value('(//Exception/State)[1]', 'varchar(255)') as [State],
		msg.description,
		cast(record as xml).value('(//Exception/UserDefined)[1]', 'int') AS [isUserDefinedError],
		cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],
		cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type], 
		cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time],
		tme.ms_ticks as [Current Time]
		from sys.dm_os_ring_buffers rbf
		cross join sys.dm_os_sys_info tme
		cross join sys.sysmessages msg
		where rbf.ring_buffer_type = 'RING_BUFFER_EXCEPTION' 
		and msg.error = cast(record as xml).value('(//Exception//Error)[1]', 'varchar(500)') and msg.msglangid = 1033 
		ORDER BY rbf.timestamp ASC



	END TRY
	BEGIN CATCH
		PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
		PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
	END CATCH
END
GO

IF OBJECT_ID ('#sp_Linux_Snapshot14','P') IS NOT NULL
   DROP PROCEDURE #sp_Linux_Snapshot14
GO

CREATE PROCEDURE #sp_Linux_Snapshot14
AS
BEGIN
	exec #sp_Linux_Snapshot
END
GO

IF OBJECT_ID ('#sp_Linux_Snapshot15','P') IS NOT NULL
   DROP PROCEDURE #sp_Linux_Snapshot15
GO

CREATE PROCEDURE #sp_Linux_Snapshot15
AS
BEGIN

	exec #sp_Linux_Snapshot14

	print '--sys.dm_pal_cpu_stats--'
	select * from sys.dm_pal_cpu_stats
	print ''

	print '--sys.dm_pal_disk_stats--'
	select * from sys.dm_pal_disk_stats
	print ''

	print '--sys.dm_pal_net_stats--'
	select * from sys.dm_pal_net_stats
	print ''

	print '--sys.dm_pal_processes--'
	select * from sys.dm_pal_processes
	print ''

	print '--sys.dm_pal_vm_stats--'
	select * from sys.dm_pal_vm_stats
	print ''

	--print '--sys.dm_pal_wait_stats--'
	--select * from sys.dm_pal_wait_stats
	--print ''

	--print '--sys.dm_pal_spinlock_stats--'
	--select * from sys.dm_pal_spinlock_stats
	--print ''

END
GO

IF OBJECT_ID ('#sp_Linux_Snapshot16','P') IS NOT NULL
   DROP PROCEDURE #sp_Linux_Snapshot16
GO

CREATE PROCEDURE #sp_Linux_Snapshot16
AS
BEGIN
	exec #sp_Linux_Snapshot15
END
GO

/*****************************************************************
*                          main loop                             *
******************************************************************/

IF OBJECT_ID ('#sp_Run_Linux_Snapshot','P') IS NOT NULL
   DROP PROCEDURE #sp_Run_Linux_Snapshot
GO
CREATE PROCEDURE #sp_Run_Linux_Snapshot  @IsLite bit=0 
AS 
	BEGIN TRY

		DECLARE @servermajorversion nvarchar(2)
		SET @servermajorversion = REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')), 2), '.', '')
		declare @#sp_Linux_Snapshot_ver sysname
		set @#sp_Linux_Snapshot_ver = '#sp_Linux_Snapshot' + @servermajorversion
		print 'executing procedure ' + @#sp_Linux_Snapshot_ver
		exec @#sp_Linux_Snapshot_ver
	END TRY
	BEGIN CATCH
	  PRINT 'Exception occured in: "' + OBJECT_NAME(@@PROCID)  + '"'     
	  PRINT 'Msg ' + isnull(cast(Error_Number() as nvarchar(50)), '') + ', Level ' + isnull(cast(Error_Severity() as nvarchar(50)),'') + ', State ' + isnull(cast(Error_State() as nvarchar(50)),'') + ', Server ' + @@servername + ', Line ' + isnull(cast(Error_Line() as nvarchar(50)),'') + char(10) +  Error_Message() + char(10);
	END CATCH
GO

exec #sp_Run_Linux_Snapshot 
