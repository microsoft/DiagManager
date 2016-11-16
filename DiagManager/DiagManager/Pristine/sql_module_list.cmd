@ECHO OFF

:Top
FOR /F "tokens=1 delims= " %%i IN ('tlist -p sqlservr.exe') DO CALL :RunForPid %%i
GOTO :eof



:RunForPid
SETLOCAL
SET SQLSERVRPID=%1

ECHO --------------------------
ECHO Executing tlist to capture module list for SQL pid %SQLSERVRPID%...
CALL OutputCurTime.cmd
tlist %SQLSERVRPID%
ECHO.

ENDLOCAL
GOTO :eof
