set MACHINENAME=%1
set INSTANCENAME=%2
set SSVER=%3

echo MACHINENAME: %MACHINENAME%
echo INSTANCENAME: %INSTANCENAME%
echo SSVER: %SSVER%

set SQLGLOBAL_VERSION=130
if "%SSVER%"=="10.50" (
 set SQLGLOBAL_VERSION=110
 ) else (
 set SQLGLOBAL_VERSION=%SSVER%0
)

echo SQLGLOBAL_VERSION: %SQLGLOBAL_VERSION%


@echo off
rem getting tools root dir
set KEY_NAME=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\%SQLGLOBAL_VERSION%
set VALUE_NAME=VerSpecificRootDir
 
FOR /F "skip=2 tokens=1,2*" %%A IN ('REG QUERY "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul') DO (
    set ValueName=%%A
    set ValueType=%%B
    set ValueValue=%%C
)

if defined ValueName (
    echo Value Name = %ValueName%
    echo Value Type = %ValueType%
    echo Value Value = %ValueValue%
) else (
    @echo "%KEY_NAME%"\"%VALUE_NAME%" not found.
)


set SQLTOOLSROOT=%ValueValue%
echo SQLTOOLSROOT:%SQLTOOLSROOT%

set SQLDUMPERPATH=%SQLTOOLSROOT%shared

echo SQLDUMPERPATH: %SQLDUMPERPATH%
