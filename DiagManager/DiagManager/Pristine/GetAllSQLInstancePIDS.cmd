@ECHO On
IF "%1"=="?" GOTO :PrintUsage
IF "%1"=="-?" GOTO :PrintUsage
IF "%1"=="/?" GOTO :PrintUsage



SET ALLSQLPIDS=
FOR /F "tokens=*" %%I IN ('tlist -s ^| findstr -I -C:"sqlservr"') DO (SET GSIP_FULL_LINE=%%I & CALL :ProcessPid)


echo %ALLSQLPIDS%
GOTO :eof

:ProcessPid
  REM    216 sqlservr.exe    Svcs:  MSSQL$SQL2K_EE
  ECHO Full Line: %GSIP_FULL_LINE%
  FOR /F "tokens=1,2 delims= " %%I IN ("%GSIP_FULL_LINE%") DO (set ALLSQLPIDS=%ALLSQLPIDS% %%I)
 GOTO :eof




:PrintUsage
  ECHO.
  ECHO   Usage:  GetAllSQLInstancePIDS.cmd
  ECHO.
  ECHO Example:  GetAllSQLInstancePIDS.cmd
  ECHO.
  ECHO   
  ECHO it will list pids like 878 1904 in one line
  ECHO 
  ECHO 
  ECHO 
  ECHO.
  GOTO :eof