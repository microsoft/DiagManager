@echo off
set ERRORLOGNUMBER=%2
if "%ERRORLOGNUMBER%" == "" goto ALL

rem individual errorlog
sqlcmd.exe -S%1 -E -w20000 -W -Q "master.dbo.xp_readerrorlog %ERRORLOGNUMBER%"

goto EOF

:ALL
sqlcmd.exe -S%1 -E -w20000 -W -icollecterrorlog.sql 


:EOF
