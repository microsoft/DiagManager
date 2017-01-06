@ECHO OFF
for /f "tokens=1-10 delims=.[] " %%i in ('ver') do set MSWINVER=%%i%%j%%k%%l%%m%%n%%o%%p%%q%%r
SET SERVER=%1
SET OUTPUTPATH="%~2"

ECHO GET_MSINFO Output Path: %OUTPUTPATH%
ECHO GET_MSINFO Server: %SERVER%
ECHO GET_MSINFO Detected OS: %MSWINVER%

IF "%MSWINVER%"=="MicrosoftWindows2000Version5002195" GOTO :MicrosoftWindows2000Version5002195
IF "%MSWINVER%"=="MicrosoftWindowsXPVersion512600" GOTO :MicrosoftWindowsXPVersion512600
IF "%MSWINVER%"=="MicrosoftWindowsVersion523790" GOTO :MicrosoftWindowsVersion523790
IF "%MSWINVER%"=="WindowsNTVersion40" GOTO :WindowsNTVersion40
REM If the OS version can't be determined, default to MSINFO32. 

REM -----------------------------
REM Win2000
:MicrosoftWindows2000Version5002195
REM WinXP
:MicrosoftWindowsXPVersion512600
REM Win2003 Server
:MicrosoftWindowsVersion523790
CALL OutputCurTime.CMD

REM Determine the actual Program Files\Common Files directory in case we are 32-bit running in WoW64
IF DEFINED CommonProgramW6432 (
  SET REAL_COMMONPROGRAMFILES="%CommonProgramW6432%"
) ELSE ( 
  SET REAL_COMMONPROGRAMFILES="%CommonProgramFiles%"
)

ECHO Generating MSInfo32 report. CmdLine: 
ECHO    START /B /WAIT "" "%REAL_COMMONPROGRAMFILES:"=%\Microsoft Shared\MSInfo\MSInfo32.exe" /computer %SERVER% /report "%OUTPUTPATH:"=%%SERVER%_MSINFO32.TXT" /categories +SystemSummary+ResourcesConflicts+ResourcesIRQS+ComponentsNetwork+ComponentsStorage+ComponentsProblemDevices+SWEnvEnvVars+SWEnvNetConn+SWEnvServices+SWEnvProgramGroup+SWEnvStartupPrograms
START /B /WAIT "" "%REAL_COMMONPROGRAMFILES:"=%\Microsoft Shared\MSInfo\MSInfo32.exe" /computer %SERVER% /report "%OUTPUTPATH:"=%%SERVER%_MSINFO32.TXT" /categories +SystemSummary+ResourcesConflicts+ResourcesIRQS+ComponentsNetwork+ComponentsStorage+ComponentsProblemDevices+SWEnvEnvVars+SWEnvNetConn+SWEnvServices+SWEnvProgramGroup+SWEnvStartupPrograms
ECHO Done.
CALL OutputCurTime.CMD
GOTO :eof




REM -----------------------------
:WindowsNTVersion40

CALL OutputCurTime.CMD
ECHO Generating MSInfo32 report. CmdLine: 
ECHO    START /B /WAIT WINMSD \\%SERVER% /a /f
START /B /WAIT WINMSD \\%SERVER% /a /f
ECHO Moving WINMSD output to %OUTPUTPATH%. CmdLine: 
ECHO    MOVE "%SystemDrive%\%SERVER%.TXT" "%OUTPUTPATH:"=%%SERVER%_WINMSD.TXT"
MOVE "%SystemDrive%\%SERVER%.TXT" "%OUTPUTPATH:"=%%SERVER%_WINMSD.TXT"
ECHO Done.
CALL OutputCurTime.CMD
GOTO :eof
