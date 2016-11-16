SETLOCAL
SET APPNAME=%1
SET OUTPUTPATH="%~2"

@ECHO OFF
CALL OutputCurTime.cmd

ECHO Enumerating active ETW traces to look for orphaned, active perfmon BLG logs 
ECHO that will prevent us from starting our own perfmon log. 
ECHO Executing: logman query -ets
logman query -ets

FOR /F "tokens=1,3" %%I IN ('logman query -ets') DO CALL :CheckForLockedBLG "%%I" "%%J"

ECHO Done. 
CALL OutputCurTime.cmd
ENDLOCAL
GOTO :eof




:CheckForLockedBLG 
SET TRCNAME=%1
SET TRCFILENAME=%2
FOR /F %%I IN ("%OUTPUTPATH:"=%\%APPNAME%.BLG") DO SET NEWBLGFILE="%%~fI"
IF /I %TRCFILENAME%==%NEWBLGFILE% (
  ECHO.
  ECHO Found an apparently orphaned %APPNAME%.BLG. This may be left behind from 
  ECHO a rudely-terminated PSSDIAG.EXE instance. 
  ECHO    Existing active log file: %TRCFILENAME%
  ECHO    Location where we will start logging: %NEWBLGFILE%
  ECHO.
  ECHO Stopping the orphaned trace so that we will be able to start a new trace
  ECHO with the same filename. 
  ECHO Executing: logman stop %TRCNAME% -ets
  logman stop %TRCNAME% -ets
)  
GOTO :eof
