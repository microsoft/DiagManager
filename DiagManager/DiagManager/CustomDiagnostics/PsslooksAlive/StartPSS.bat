@echo off

call SetupVars.bat

REM Strip out trailing backslash if present at end of directory. 
if (%PSSLOOKSALIVEFILEPATH:~-1%) == (\) set PSSLOOKSALIVEFILEPATH=%PSSLOOKSALIVEFILEPATH:~0,-1%

set LOGFILEPATH=%PSSLOOKSALIVEFILEPATH%
set DUMPFILEPATH=%PSSLOOKSALIVEFILEPATH%

call DoLooksAlive.bat 
