@ECHO OFF
ECHO DoLooksAlive started...
REM This batch file (DoLooksAlive.BAT) is called by either StartPSS.BAT (when 
REM started manually) or by StartFromPSSDIAG.BAT (when launched by PSSDIAG). 
rem
REM It expects four environment variables to be set: 
REM    SECURITY		Either "-E" (Windows auth) or "-Usa -P<pwd>"
REM    SERVERNAME	Name of machine hosting the SQL instance (srv)
REM    SQLSERVERNAME	Name of SQL instance to connect to (srv\inst)
REM    INSTANCENAME	Name of SQL instance to connect to (inst)
REM    LOGFILEPATH	Output directory for log files
REM    DUMPFILEPATH	Output directory for userdump

REM "Uniqueify" the log file name with the server name to allow for multiple 
REM instances of the script
IF (%SERVERNAME%)==(.) SET SERVERNAME=%COMPUTERNAME%
SET LOGFILEPREFIX=%SERVERNAME%_%INSTANCENAME%_PSSLooksAlive_
SET BATCHLOG=%LOGFILEPATH%\%LOGFILEPREFIX%LooksAliveBatch.log
SET FIRSTRETRYLOG=%LOGFILEPATH%\%LOGFILEPREFIX%LooksAliveFirstRetry.log
SET SECONDRETRYLOG=%LOGFILEPATH%\%LOGFILEPREFIX%LooksAliveSecondRetry.log
SET THIRDRETRYLOG=%LOGFILEPATH%\%LOGFILEPREFIX%LooksAliveThirdRetry.log

REM For display of parameters, strip out the password that was passed in 
REM so we can just display the username. 
SET SECURITYDISPLAY=
IF ("%SECURITY%")==("-E") (
  SET SECURITYDISPLAY=-E
) ELSE (
  for /f "tokens=1" %%I in ('ECHO %SECURITY%') do SET SECURITYDISPLAY=%%I -P...
)


ECHO ===============================
ECHO Variables being used:
ECHO   SERVERNAME=%SERVERNAME%
ECHO   SQLSERVERNAME=%SQLSERVERNAME%
ECHO   INSTANCENAME=%INSTANCENAME%
ECHO   SECURITY=%SECURITYDISPLAY%
ECHO   LOGFILEPATH=%LOGFILEPATH%
ECHO   DUMPFILEPATH=%DUMPFILEPATH%
ECHO ===============================

ECHO. 					
ECHO Retreiving process id for instance "%INSTANCENAME%" on local server %SERVERNAME%
SET ATTACHBYNAME=0

CALL GetSQLInstancePID.CMD %INSTANCENAME%
SET PROCESSID=%SQLPID%

REM    -- Old way of retrieving SQL PID (via osql) is no longer needed now that we use GetSQLInstancePID.CMD. 
REM   osql %SECURITY% -S%SQLSERVERNAME%  -Q "exit(set nocount on select serverproperty('processid'))" -h-1 -n >> %BATCHLOG%
REM   REM SQL7.0 can't return it's process ID -- detect a failed attempt to retrieve process ID
REM   REM and make a note of it.  If %ATTACHBYNAME%=1, the debugger will be attached by exe name
REM   REM to sqlservr.exe instead of to a particular process ID. 
REM   SET PROCESSID=%ERRORLEVEL%
REM   IF (%PROCESSID%)==(-100) SET ATTACHBYNAME=1
REM   REM osql will return an errorlevel of 1 if it fails to connect. 
REM   IF (%PROCESSID%)==(1) SET ATTACHBYNAME=1

IF (%ATTACHBYNAME%)==(0) (
  ECHO ==============================	
  ECHO Using ProcessID=%PROCESSID% 	
  ECHO ==============================	
  ECHO. 					
) ELSE (
  ECHO.
  ECHO Failed to retrieve SQL process ID -- may be SQL7
  ECHO Will attach by name to sqlservr.exe
  ECHO.
)  
@echo off
REM Shared memory netlib doesn't honor login timeout (webdata #105120). Force the IsAlive check to use a 
REM particular netlib to avoid shared memory, but only if we can confirm that the server is listening on 
REM the netlib. 
SET ORIGSQLSERVERNAME=%SQLSERVERNAME%

echo checking for Named pipe connectivity
SET SQLSERVERNAME=np:%ORIGSQLSERVERNAME%
CALL :TestBatch NUL
IF %errorlevel%==70000 GOTO :Continue
ECHO Test for Named Pipes connectivity failed.

ECHO Checking for TCP/IP connectivity. 
SET SQLSERVERNAME=tcp:%ORIGSQLSERVERNAME%
CALL :TestBatch NUL
IF %errorlevel%==70000 GOTO :Continue
ECHO Test for TCP/IP connectivity failed. 
SET SQLSERVERNAME=rpc:%ORIGSQLSERVERNAME%
CALL :TestBatch NUL
IF %errorlevel%==70000 GOTO :Continue
ECHO Test for Multiprotocol/RPC connectivity failed. 
REM If we can't confirm connectivity via a specific netlib, don't force a particular netlib. Let DBNETLIB 
REM do its best. 
SET SQLSERVERNAME=%ORIGSQLSERVERNAME%

:Continue
ECHO Using modified SQL Server name "%SQLSERVERNAME%". 

ECHO.

CALL :OutputDateTime
ECHO Initiating LooksAlive Batch. Detailed log files are:
ECHO    %BATCHLOG%; 
ECHO    %FIRSTRETRYLOG%; 
ECHO    %SECONDRETRYLOG%; 
ECHO    %THIRDRETRYLOG%

:top
ECHO.
ECHO Executing LooksAlive MainLoop...
CALL :TestBatch "%BATCHLOG%"
IF NOT ERRORLEVEL 70000 goto :FirstRetry
WAITFOR 5 
goto :top

:FirstRetry
REM Retrying First time, if success, then go back to top, else go to SecondRetry
ECHO.
ECHO invoking xperf
call xperf_cpu_start.bat
ECHO Executing First Retry, %FIRSTRETRYLOG% for details
CALL :TestBatch "%FIRSTRETRYLOG%"
IF NOT ERRORLEVEL 70000 goto :SecondRetry
ECHO Going back to MainLoop. First Retry Connection worked.
call xperf_cpu_stop.bat "%LOGFILEPATH%\xperf1.etl"
goto :top

:SecondRetry
REM Retrying Second time, if success, then go back to top, else go to ThirdRetry
ECHO.
ECHO Executing Second Retry, see %SECONDRETRYLOG% for details
CALL :TestBatch "%SECONDRETRYLOG%"
IF NOT ERRORLEVEL 70000 goto :ThirdRetry
ECHO Going back to MainLoop. Second Retry Connection worked.
call xperf_cpu_stop.bat "%LOGFILEPATH%\xperf2.etl"
goto :top

:ThirdRetry
call xperf_cpu_stop.bat "%LOGFILEPATH%\xperf3.etl"
  echo attempting to do lpc to get ring buffer
  set RBLPC=%LOGFILEPATH%\%LOGFILEPREFIX%PssLookAlive_ringbuffer_lpc.out
  echo RBLPC %RBLPC%
  set RBLPC="%RBLPC:"=%"
  echo RBLPC %RBLPC%
  set RBADMIN=%LOGFILEPATH%\%LOGFILEPREFIX%PssLooksAlive_ringbuffer_admin.out
  echo RBADMIN: %RBADMIN%
  set RBADMIN="%RBADMIN:"=%"
  echo RBADMIN: %RBADMIN%
ECHO.
ECHO Executing Third Retry, see %THIRDRETRYLOG% for details
CALL :TestBatch "%THIRDRETRYLOG%"
IF NOT ERRORLEVEL 70000 (
  echo osql  -Slpc:%ORIGSQLSERVERNAME% -Q"select getdate() as startime select * from sys.dm_os_ring_buffers select getdate() endtime" -b -n -l15 -t15 -w8000 -o%RBLPC%
  osql %SECURITY% -Slpc:%ORIGSQLSERVERNAME% -Q"select getdate() as startime select * from sys.dm_os_ring_buffers select getdate() endtime" -b -n -l15 -t15 -w8000 -o%RBLPC%
  echo osql  -Sadmin:%ORIGSQLSERVERNAME% -Q"select getdate() as startime select * from sys.dm_os_ring_buffers select getdate() endtime" -b -n -l15 -t15 -w8000 -o%RBADMIN%
  osql %SECURITY% -Sadmin:%ORIGSQLSERVERNAME% -Q"select getdate() as startime select * from sys.dm_os_ring_buffers select getdate() endtime" -b -n -l15 -t15 -w8000 -o%RBADMIN%
  CALL :AutoGenerateUserDump MINI
  ECHO mini dump generated. Exiting. 
  goto :Done
)
ECHO Going back to MainLoop. Third Retry Connection worked.
goto :top



:TestBatch
SET OSQLLOGFILE=%1
IF "%OSQLLOGFILE:"=%" NEQ "NUL" SET OSQLLOGFILE="%OSQLLOGFILE:"=%"
CALL :OutputDateTime
ECHO time from client before invoking osql: %date% %time% >>  %OSQLLOGFILE%
echo osql -S%SQLSERVERNAME% -iLooksAliveBatch.sql -b -n -l15 -t15 -w2000  [security mode is skipped to avoid leaking password]
echo osql -S%SQLSERVERNAME% -iLooksAliveBatch.sql -b -n -l15 -t15 -w2000  [security mode is skipped to avoid leaking password]   >> %OSQLLOGFILE%
osql %SECURITY% -S%SQLSERVERNAME% -iLooksAliveBatch.sql -b -n -l15 -t15 -w2000 >> %OSQLLOGFILE%
IF %errorlevel%==70000 (
  ECHO LooksAliveBatch succeeded
) ELSE (
  ECHO LooksAliveBatch FAILED
  ECHO Errorlevel: %errorlevel%
)
goto :eof


:AutoGenerateUserDump
SET MINI_OR_FULL=%1
REM Pass in "MINI" (w/o quotes) to generate a minidump instead of a full dump. 
ECHO.
CALL :OutputDateTime
ECHO Running sqldumper to get a mini userdump by default
CALL AutoUserDump.bat %PROCESSID% "%DUMPFILEPATH:"=%" %ATTACHBYNAME% %MINI_OR_FULL%   > "%OUTPUTPATH%\%SERVERNAME%_%INSTANCENAME%_PsslooksAlive_AutoUserDump.bat.out" 2>&1
goto :eof


:OutputDateTime
REM Print out current date and time. 
CALL OutputCurTime
REM Return to caller
goto :EOF


:Done
