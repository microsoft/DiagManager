@ECHO OFF
SETLOCAL

SET DIR=%1
IF (%DIR%)==() SET DIR=.
SET DIR=%DIR:"=%
IF "%DIR%"=="" SET DIR=.

SET RECURSIVE=/S

REM Basic checks for potentially unsafe (extremely long-running) parameter values. 
REM For any of these cases we will skip recursive directory traversal. 
REM ---- Wildcard without a dir specified
IF "%DIR%"=="" CALL :DontRecurseEntireDrive
IF "%DIR:~0,1%"=="*" CALL :DontRecurseEntireDrive
REM ---- Root dir w/o drive letter (but don't disallow UNCs)
IF "%DIR%"=="\" CALL :DontRecurseEntireDrive
IF "%DIR:~0,2%" NEQ "\\" (
  IF "%DIR:~0,2%"=="\*" CALL :DontRecurseEntireDrive
)
REM ---- Filespec with leading wildcard specified at root of drive
IF "%DIR:~1,3%"==":\*" CALL :DontRecurseEntireDrive
IF "%DIR:~1,3%"==":\" CALL :DontRecurseEntireDrive



ECHO ---------------------------
ECHO --------- Summary file list
ECHO ---------------------------
ECHO ---- filever %RECURSIVE% "%DIR%
filever %RECURSIVE% "%DIR%
ECHO.
ECHO.
ECHO.
ECHO.
ECHO ---------------------------
ECHO --------- Verbose file list
ECHO ---------------------------
ECHO ---- filever %RECURSIVE% /V "%DIR%
filever %RECURSIVE% /V "%DIR%

ENDLOCAL
GOTO :eof



:DontRecurseEntireDrive
  ECHO Refusing to do recursive dump of root directory (%DIR%). 
  SET RECURSIVE=
  GOTO :eof
