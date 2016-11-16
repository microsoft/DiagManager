@ECHO OFF

IF "%1"=="/?" GOTO :PrintUsage
IF "%1"=="-?" GOTO :PrintUsage
IF "%1"=="?" GOTO :PrintUsage

SETLOCAL
SET INSTANCE=%1
IF "%INSTANCE%" NEQ "" SET %INSTANCE:"=%

IF EXIST ".\OUTPUT\" (
  SET OUTPUTPATH=.\OUTPUT
) ELSE (
  SET OUTPUTPATH=.
)

IF "%INSTANCE%"=="" (
  ECHO Attempting to locate PID for default instance ^(MSSQLServer^)...
) ELSE (
  ECHO Attempting to locate PID for instance %INSTANCE% ^(MSSQL$%INSTANCE%^)...
)
CALL GetSQLInstancePID.CMD %INSTANCE%
IF "%SQLPID%"=="0" (
  ECHO ERROR: Failed to locate PID for SQL Server instance "%INSTANCE%". 
  ECHO        Is the SQL Server service running? 
  GOTO :eof
)

ECHO CmdLine: sqlfiltereddump.exe %SQLPID% "%OUTPUTPATH%"
sqlfiltereddump.exe %SQLPID% "%OUTPUTPATH%"
GOTO :eof


:PrintUsage
  ECHO.
  ECHO   Usage:  ManualUserDump.CMD [sqlinstancename]
  ECHO.
  ECHO Example (dump MSSQL$MyInstance):   ManualUserDump.CMD MyInstance
  ECHO Example (dump default instance):   ManualUserDump.CMD 
  ECHO.
  ECHO Only include the instance name; do not pass in the server name 
  ECHO (server\instance).  For a default instance of SQL Server, omit the 
  ECHO "sqlinstancename" parameter. 
  ECHO.
  GOTO :eof
