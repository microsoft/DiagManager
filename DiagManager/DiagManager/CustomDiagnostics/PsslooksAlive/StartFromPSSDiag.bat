@ECHO OFF
rem This is invoked from PSSDIAG with a custom utility command: 
rem
rem      StartFromPSSDiag.bat %server% %server_nstance% "%instance%" "%output_path%" %authmode% %ssuser% %sspwd% %ssver%
rem
rem %authmode% is either 1 (Windows auth) or 0 (SQL auth).  If %authmode%=0, then 
rem %ssuser% and %sspwd% will be provided. 

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

call DoLooksAlive.bat > "%OUTPUTPATH%\%SERVERNAME%_%INSTANCENAME%_PSSLooksAlive_DoLooksAliveLoop.out" 2>&1




