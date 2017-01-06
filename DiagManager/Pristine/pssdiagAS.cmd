@echo off
IF "%1"=="?" GOTO :PrintUsage
IF "%1"=="-?" GOTO :PrintUsage
IF "%1"=="/?" GOTO :PrintUsage

InterCounters.exe
set CollectorEXE=pssdiagAS_Internal.exe

rem if  EXIST HASAMO.TXT  DEL HASAMO.TXT

rem powershell -command set-executionpolicy Unrestricted
rem powershell .\discover.ps1

rem if NOT EXIST HASAMO.TXT goto NOAMO

set launchdir=%~dp0
if "%1"=="/R"  goto Register
if "%1"=="/r"  goto Register
if "%1"=="stop" goto ServiceOp
if "%1"=="STOP" goto ServiceOp
if "%1"=="START" goto ServiceOp
if "%1"=="start" goto ServiceOp
if "%1"=="/U" goto ServiceOp
if "%1"=="/u" goto ServiceOp



 
%CollectorEXE% /O output /I pssdiag.xml /P %1 %2 %3 %4 %5 %6 %7 %8 %9

goto eof


:Register

 %CollectorEXE% /R /O"%launchdir%output" /I"%launchdir%pssdiag.xml" %2 %3 %4 %5 %6 %7
goto EOF

:ServiceOp
	 %CollectorEXE%  %1
@echo off
goto eof



:PrintUsage
@echo off
  echo  . 
  %CollectorEXE% /?  
  goto EOF

:NOAMO
  @echo off
  echo #########################################################################
  echo The version of AMO required to run is not install on this machine
  echo You do not have Analysis Service compoent installed
  echo AS Pssdiag will NOT run
  echo #########################################################################
  

:EOF