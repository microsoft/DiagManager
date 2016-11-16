@ECHO OFF
REM REG.EXE output looks like this:
REM
REM ! REG.EXE VERSION 2.0
REM 
REM HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\80
REM     SharedCode  REG_SZ  C:\Program Files\Microsoft SQL Server\80\COM\
REM 
REM If provided with a reg key and value, this batch file will output to stdout 
REM only the value's data ("C:\Program Files\Microsoft SQL Server\80\COM\"), in 
REM the example above. 
REM 
REM Data is written to stdout, and also stored in env var %GETREG_RESULT%. 

SET GETREG_KEY=%1
SET GETREG_VALUE=%2
REM Strip off any double quote delimiters around reg key.
IF (^%GETREG_KEY:~-1%) == (^") set GETREG_KEY=%GETREG_KEY:"=%
REM Strip off any double quote delimiters around reg value.
IF (^%GETREG_VALUE:~-1%) == (^") set GETREG_VALUE=%GETREG_VALUE:"=%

REM The delimiter in the FOR below is a TAB character. This is what REG.EXE uses
REM to delimit the three elements in its final output line. 
FOR /F "tokens=3* delims=	 " %%I IN ('reg query "%GETREG_KEY%" /v "%GETREG_VALUE%" ^| findstr -I -C:"%GETREG_VALUE%"') DO SET GETREG_RESULT=%%I %%J
ECHO %GETREG_RESULT%
