@echo off
rem AutoUserDump expects four command line params: 
rem 
rem    <process ID>	PID of the process to capture a userdump of
rem    <output dir>	Directory for log and .DMP file
rem    <attach by name>	If 1, attach to sqlservr.exe.  If 0, attach to the provided process ID.
rem    <full_or_mini>   If "MINI", get a mini dump. Otherwise, get a full dump.  OBSOLETE -- now ignored.  

SET SQLPID=%1
SET DUMPPATH=%2
SET ATTACHBYNAME=%3
SET DUMPMODE=%4

echo SQLPID: %SQLPID%
echo DUMPPATH: %DUMPPATH%
echo ATTACHBYNAME: %ATTACHBYNAME%
echo DUMPMODE: %DUMPMODE%

REM Strip out any quotes around dump output directory. 
set DUMPPATH=%DUMPPATH:"=%
REM Strip out trailing backslash if present at end of directory. 
if (%DUMPPATH:~-1%) == (\) set DUMPPATH=%DUMPPATH:~0,-1%

REM 20040811 - Replaced cdb-based dump with SFDLive. 
REM ----------------
REM rem cdb -pv -p %SQLPID% -c "$<%2\ntsd.ini"
REM 
REM if (%SQLPID%)==(0) (
REM   rem We are supposed to attach to a particular process ID. 
REM   cdb -pv -p %SQLPID% -loga %DUMPPATH%\PSSLooksAlive_CDB.log -c ".time;.dump /ma /u %DUMPPATH%\sqlservr.dmp;.time;q"
REM ) else (
REM   rem We are supposed to attach by name to sqlservr.exe. 
REM   cdb -pv -pn sqlservr.exe -loga %DUMPPATH%\PSSLooksAlive_CDB.log -c ".time;.dump /ma /u %DUMPPATH%\sqlservr.dmp;.time;q"
REM )


if (%ATTACHBYNAME%)==(1) (
  rem We weren't provided with the SQL PID. Get it so we can pass it to SqlFilteredDump. 
  FOR /F "tokens=1 delims= " %%i IN ('tlist -p sqlservr.exe') DO SET SQLPID=%%i
)

REM 20050802 - Replaced SFDLive.exe-based dump with SqlFilteredDump.exe. 
REM REM SFDLive will generate a minidump if told to "TEST". 
REM IF "%MINI%"=="MINI" (
REM   SET SQLDUMPCMDLINE=sfdlive.exe %SQLPID% "%DUMPPATH%\SFDLive_SQLSERVR_AUTO_MINI_PID%SQLPID%" TEST
REM ) ELSE (
REM   SET SQLDUMPCMDLINE=sfdlive.exe %SQLPID% "%DUMPPATH%\SFDLive_SQLSERVR_AUTO_FULL_PID%SQLPID%"
REM )
REM ECHO CmdLine: %SQLDUMPCMDLINE%
REM %SQLDUMPCMDLINE%



call SetSqlEnvVariables.cmd %SERVERNAME% %INSTANCENAME% %SSVER%


rem sqldumper.exe 
rem fulldump: ProcessID 0 0x01100  
rem mini-dump: ProcessID 0 0x0120
rem mini-dump file including indirect referenced memroy: ProcessID 0 0x0120:40
rem filtered dump  ProcessID 0 0x8100


rem old one
rem SET SQLDUMPCMDLINE=sqlfiltereddump.exe %SQLPID% "%OUTPUTPATH%"
rem if "%DUMPMODE%"=="MINI"  set DUMPFLAGS=0x0120:40
rem if "%DUMPMODE%"=="FILTERED"  set DUMPFLAGS=0x8100
rem if %DUMPMODE%"=="FULL"  set DUMPFLAGS=0x01100

rem only do min with indirect memory reference
SET SQLDUMPCMDLINE="%SQLDUMPERPATH%\sqldumper.exe" %SQLPID% 0 0x0120:40 0 "%DUMPPATH%"


ECHO CmdLine: %SQLDUMPCMDLINE%
echo invoking sql dumper
CALL OutputCurTime
%SQLDUMPCMDLINE% 
echo Finished invoking sqldumper
CALL OutputCurTime
