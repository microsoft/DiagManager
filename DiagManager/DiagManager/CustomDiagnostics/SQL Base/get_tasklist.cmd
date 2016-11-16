@ECHO OFF
ECHO This task relies on TASKLIST.EXE, which is present on Win XP/2003 and later. 
ECHO. 
ECHO Start time: %date% %time%

ECHO.
ECHO. 
ECHO TASKLIST /V (process list)
TASKLIST /V

ECHO.
ECHO.
ECHO TASKLIST /SVC (service list)
TASKLIST /SVC

ECHO.
ECHO.
ECHO TASKLIST /M (module list)
TASKLIST /M 

ECHO.
ECHO. 
ECHO End time: %date% %time%
