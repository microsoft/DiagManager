rem ConnectivityTest.bat %server% %server_nstance% "%instance%" "%output_path%" %authmode% %ssuser% %sspwd% %ssver%

@ECHO OFF
ECHO Connectivity testing started
REM this batch file just trying to make connection every 5 seconds until pssdiag shuts down


REM It expects four environment variables to be set: 
REM    SECURITY		Either "-E" (Windows auth) or "-Usa -P<pwd>"
REM    SERVERNAME	Name of machine hosting the SQL instance (srv)
REM    SQLSERVERNAME	Name of SQL instance to connect to (srv\inst)
REM    INSTANCENAME	Name of SQL instance to connect to (inst)
REM    LOGFILEPATH	Output directory for log files
REM    DUMPFILEPATH	Output directory for userdump


ECHO PSSLooksAlive Parameters:
ECHO    SERVERNAME: %1
ECHO    SQLSERVERNAME: %2
ECHO    INSTANCENAME: %3
ECHO    OUTPUTPATH: %4
ECHO    AUTHMODE: %5
ECHO    SQLUSER: %6


rem Define the env vars that DoLooksAlive.bat expects. 
SET SERVERNAME=%1
SET SQLSERVERNAME=%2
SET INSTANCENAME=%3
set OUTPUTPATH=%4
set AUTHMODE=%5
if "%AUTHMODE%"=="1" (
	set SSVER=%7
	) else (
	set SSVER=%8
)

echo SSVER: %SSVER%
rem -- Strip off quote delimiters (needed to handle default instance name, which is an empty string)
IF "%INSTANCENAME:"=%" NEQ "" SET INSTANCENAME=%INSTANCENAME:"=%

SET LOGFILEPATH=%4
rem -- Strip off quote delimiters.
IF "%LOGFILEPATH:"=%" NEQ "" SET LOGFILEPATH=%LOGFILEPATH:"=%
rem -- Strip out trailing backslash if present at end of LOGFILEPATH. 
if (^%LOGFILEPATH:~-1%) == (^\) SET LOGFILEPATH=%LOGFILEPATH:~0,-1%

SET DUMPFILEPATH=%LOGFILEPATH%

ECHO    LOGFILEPATH: %LOGFILEPATH%
ECHO    DUMPFILEPATH: %DUMPFILEPATH%

if (%5)==(0) (
  ECHO Launching DoLooksAlive with SQL auth ^(SQL login: %6^)
  SET SECURITY=-U%6 -P%7
) else (
  SET SECURITY=-E
  ECHO Launching DoLooksAlive with NT auth
)





REM "Uniqueify" the log file name with the server name to allow for multiple 
REM instances of the script
IF (%SERVERNAME%)==(.) SET SERVERNAME=%COMPUTERNAME%
SET LOGFILEPREFIX=%SERVERNAME%_%INSTANCENAME%_PsslookAlive_
SET BATCHLOG=%LOGFILEPATH%\%LOGFILEPREFIX%ConnectivityTestBatch.log


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




CALL :OutputDateTime
ECHO Initiating LooksAlive Batch. Detailed log files are:
ECHO    %BATCHLOG%; 
ECHO    %FIRSTRETRYLOG%; 
ECHO    %SECONDRETRYLOG%; 
ECHO    %THIRDRETRYLOG%

:top
ECHO.
ECHO Executing LooksAlive MainLoop...
CALL :TestBatch2 "%BATCHLOG%" np
CALL :TestBatch2 "%BATCHLOG%" lpc
CALL :TestBatch2 "%BATCHLOG%" tcp
CALL :TestBatch2 "%BATCHLOG%" admin

WAITFOR 5 
goto :top





:TestBatch2 
SET OSQLLOGFILE=%1
set PROTOCOL=%2
IF "%OSQLLOGFILE:"=%" NEQ "NUL" SET OSQLLOGFILE="%OSQLLOGFILE:"=%"

CALL :OutputDateTime
echo time from client before invoking osql: %date% %time% >>  %OSQLLOGFILE%
osql %SECURITY% -S%PROTOCOL%:%SQLSERVERNAME% -iLooksAliveBatch.sql -b -n -l15 -t15 -w2000 >> %OSQLLOGFILE%
IF %errorlevel%==70000 (
  ECHO ConnectivityTest.Bat succeeded for %PROTOCOL%
) ELSE (
  ECHO ConnectivityTest.Bat FAILED for %PROTOCOL%
  ECHO Errorlevel: %errorlevel%
)
goto :eof



:OutputDateTime
CALL OutputCurTime
goto :EOF


:Done
