@ECHO On
IF "%1"=="?" GOTO :PrintUsage
IF "%1"=="-?" GOTO :PrintUsage
IF "%1"=="/?" GOTO :PrintUsage

set INSTANCENAMESTRIPPED=%1
set INSTANCENAMESTRIPPED=%INSTANCENAMESTRIPPED:"=%
 
 IF "%INSTANCENAMESTRIPPED%"=="" set GSIP_INSTANCE=MSSQLSERVER

 IF NOT "%INSTANCENAMESTRIPPED%"=="" SET GSIP_INSTANCE=%INSTANCENAMESTRIPPED%
IF NOT "%INSTANCENAMESTRIPPED%"=="" SET SERVICEPREFIX=MSSQL$

IF (^%GSIP_INSTANCE:~-1%) == (^") SET GSIP_INSTANCE=%GSIP_INSTANCE:"=%
SET SQLPID=
FOR /F "tokens=*" %%I IN ('tlist -s ^| findstr -I -C:"sqlservr"') DO (SET GSIP_FULL_LINE=%%I & CALL :ProcessInstance)
IF "%SQLPID%"=="" SET SQLPID=0
ECHO %SQLPID%
GOTO :eof


:ProcessInstance
  REM Strip off quote delimiters from around FULL_LINE, if present.
  if (^%GSIP_FULL_LINE:~-1%) == (^") set GSIP_FULL_LINE=%GSIP_FULL_LINE:"=%
  REM Full line will look like this: 
  REM    216 sqlservr.exe    Svcs:  MSSQL$SQL2K_EE
  REM ECHO Full Line: %GSIP_FULL_LINE%
  FOR /F "tokens=1,4 delims= " %%I IN ("%GSIP_FULL_LINE%") DO (CALL :CheckInstance %%I %%J)
  GOTO :eof

:CheckInstance
  SET GSIP_PID=%1
  SET GSIP_SVCNAME=%2
  REM ECHO Found SQL Service %GSIP_SVCNAME% with PID %GSIP_PID%. 
  REM Handle special case of default instance. 
  IF /I "%GSIP_SVCNAME%"=="MSSQLSERVER" (
    IF /I "%GSIP_INSTANCE%" == "" (
      SET SQLPID=%GSIP_PID%
      GOTO :eof
    )
  )
  REM Handle named instances.
  IF /I "%GSIP_SVCNAME%"=="%SERVICEPREFIX%%GSIP_INSTANCE%" (
    SET SQLPID=%GSIP_PID%
    GOTO :eof
  )
  GOTO :eof




:PrintUsage
  ECHO.
  ECHO   Usage:  GetSQLInstancePID.CMD [instancename]
  ECHO.
  ECHO Example:  GetSQLInstancePID.CMD MyInstance
  ECHO.
  ECHO Only include the instance name. Do not pass in the server name (server\instance).  
  ECHO This cmd file is only able to retrieve PIDs for SQL instances running on the local 
  ECHO machine.  The PID of the target SQL instance is returned to stdout and in a  
  ECHO %SQLPID% environment variable.  A PID of 0 indicates failure.  For a default 
  ECHO instance, you should not pass in anything. 
  ECHO.
  GOTO :eof
