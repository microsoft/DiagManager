REM Make sure we have the most up-to-date set of SqlFilteredDump files. 

SETLOCAL
SET PSSDIAG_BUILD_PATH=%1
SET SSVER=%2
SET TARGET_PLATFORM=%3

REM -- Strip off quote delimiters from around PSSDIAG_BUILD_PATH. 
if (^%PSSDIAG_BUILD_PATH:~-1%) == (^") set PSSDIAG_BUILD_PATH=%PSSDIAG_BUILD_PATH:"=%
REM -- Strip out trailing backslash if present at end of PSSDIAG_BUILD_PATH. 
if (^%PSSDIAG_BUILD_PATH:~-1%) == (^\) set PSSDIAG_BUILD_PATH=%PSSDIAG_BUILD_PATH:~0,-1%

CALL "%PSSDIAG_BUILD_PATH%\..\SharedDiagnostics\SqlFilteredDump\BUILD.CMD" "%PSSDIAG_BUILD_PATH%\" %TARGET_PLATFORM%

ENDLOCAL
