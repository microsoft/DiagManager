@ECHO OFF
for /f "tokens=1-10 delims=.[] " %%i in ('ver') do set MSWINVER=%%i%%j%%k%%l%%m%%n%%o%%p%%q%%r
SET SERVER=%1
SET OUTPUTPATH="%~2"

ECHO GET_SYSTEMINFO Output Path: %OUTPUTPATH%
ECHO GET_SYSTEMINFO Server: %SERVER%
ECHO GET_SYSTEMINFO Detected OS: %MSWINVER%

REM CALL OutputCurTime.CMD
Powershell -Command "Get-Date -Format "yyyy-MM-dd HH:mm:ss""

ECHO Generating Systeminfo report. CmdLine: 
START /B /WAIT "" systeminfo.exe /FO LIST > "%OUTPUTPATH:"=%%SERVER%_SYSTEMINFO32.TXT" 
ECHO Done.

REM CALL OutputCurTime.CMD
Powershell -Command "Get-Date -Format "yyyy-MM-dd HH:mm:ss""
GOTO :eof

