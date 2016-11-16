@echo off
REM -- Recursive version of MULTICOPY.CMD.  Copies all files matching a given filespec 
REM -- to the current directory.  Adds a prefix to each file. 
REM
REM Usage: 
REM    MULTICOPYR.CMD <filespec> <prefix>
REM
REM Example: 
REM    MULTICOPYR.CMD C:\WINDOWS\setup*.LOG WINSETUPLOGS_
REM

REM Enable command extensions.  Detect if the OS version doesn't support them. 
SET CmdExtEnabled=1
VERIFY OTHER 2>nul
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 1 (
  ECHO Could not enable command extensions. Resorting to non-recursive copy. 
  SET CmdExtEnabled=0
  SETLOCAL
)

set mask=%1
set prefix=%2

rem Remove quotes since we supply them below
set mask=%mask:"=%
set prefix=%prefix:"=%

REM Do directory recursion if the necessary cmd extensions are available. 
if (%CmdExtEnabled%==1) goto :RecursiveCopy
goto :FlatCopy

:RecursiveCopy
  rem Remove surrounding quotes and expand path. 
  for /F %%I in ("%mask%") do set mask=%%I

  rem Break the input file mask into filename and path. 
  rem First get the path. 
  for /F %%I in ("%mask%") do set filepath=%%~dpI

  rem Eliminate the directory portion of the filemask. E.g. from "C:\temp\*.LOG", we want just "*.LOG". 
  set tmppath=%filepath%
  set filemask=%mask%
  :stripleadingchar
  rem Get rid of the first character
  set tmppath=%tmppath:~1%
  set filemask=%filemask:~1%
  rem Stop stripping characters off the beginning of each string once we've consumed the entire path. 
  if "%tmppath%" neq "" goto :stripleadingchar

  rem The filename portion is the part of the mask that follows the path. 

  rem Copy multiple files recursively and prefix each with the specified prefix
  for /R %filepath% %%i in ("%filemask%") do (
    rem echo copy /Y "%%i" "%prefix%%%~nxi"
    copy /Y "%%i" "%prefix%%%~nxi" 
  )
  endlocal
goto :eof


:FlatCopy
  rem Copy multiple files and prefix each with the specified prefix
  for %%i in ("%mask%") do (
    rem echo copy "%%i" "%prefix%%%~nxi"
    copy /Y "%%i" "%prefix%%%~nxi" 
  )
  endlocal
goto :eof

