@ECHO OFF

REM 
REM This batch file emits the instance name and instance directory for each detected SQL 
REM instance on the machine.  It was created to enable automatic log file collection for 
REM setup failure cases where setup may have removed all record of the failed install from 
REM the registry.  This will prevent PSSDIAG's automatic instance enumeration from 
REM detecting the instance, which makes it difficult to automatically collect all the 
REM setup logs for the instance.  
REM 
REM The instance name and path for each instance are returned on the same line, delimited 
REM by a forward slash "/". Example output: 
REM 
REM    MSSQLServer/C:\Program Files\Microsoft SQL Server\MSSQL
REM    SQL1/C:\Program Files\Microsoft SQL Server\MSSQL$SQL1
REM    TestInstance/C:\Program Files\Microsoft SQL Server\MSSQL$TestInstance
REM 
REM Note that the default instance (first line) has an instance name of MSSQLServer. 
REM Here's one way to break apart this pair of values (assumed to be in the %InstID%
REM env variable in this example) into separate variables: 
REM
REM     FOR /F "tokens=1,2* delims=/" %%I IN ("%InstID%") DO (SET InstName=%%I& SET InstPath="%%J")
REM     ECHO Instance Name=%InstName%
REM     ECHO Instance Path=%InstPath%
REM

REM First handle SQL 2000 instances in the default location. 
FOR /D %%I IN ("%ProgramFiles%\Microsoft SQL Server\*") DO CALL :CheckIfValidInstance "%%I" 
IF DEFINED ProgramW6432 FOR /D %%I IN ("%ProgramW6432%\Microsoft SQL Server\*") DO CALL :CheckIfValidInstance "%%I" 

REM Check for a default 7.0 instance in the default location (C: or D: drives)
IF EXIST C:\MSSQL7 ECHO MSSQLServer/C:\MSSQL7
IF EXIST D:\MSSQL7 ECHO MSSQLServer/D:\MSSQL7

GOTO :eof


:CheckIfValidInstance
SET FullInstanceDir=%1

FOR %%I IN ("%FullInstanceDir:"=%") DO SET ShortInstanceDir=%%~nxI

REM What we have left is either "MSSQL$instance", "MSSQL", or "MSSQL.1" if the dir represents a valid SQL instance. 
IF "%ShortInstanceDir:~0,5%" NEQ "MSSQL" (
  SET InstanceDir=
  SET InstanceName=
  GOTO :eof
)
REM This appears to be an actual SQL instance directory -- output the instance name and path. 
SET InstanceName=%ShortInstanceDir:~6%
IF "%ShortInstanceDir:~0,6%"=="MSSQL." SET InstanceName=%ShortInstanceDir%
IF "%InstanceName%"=="" SET InstanceName=MSSQLServer
ECHO %InstanceName%/%FullInstanceDir%
GOTO :eof
