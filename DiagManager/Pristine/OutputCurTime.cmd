@ECHO OFF
REM FOR /F "tokens=*" %%I IN ('date /T') DO SET CURDATE=%%I
REM FOR /F "tokens=1,2,3,4,5 delims=:" %%I IN ('echo. ^| time') DO (
REM   REM Pull hours, min, seconds from output string: "The current time is: 12:24:58.40"
REM   SET CURTIME=%%J:%%K:%%L
REM   GOTO Done
REM )
REM 
REM :Done
REM 
REM ECHO %CURDATE%%CURTIME% - %* 


cscript outputcurtime.vbs %* //Nologo
