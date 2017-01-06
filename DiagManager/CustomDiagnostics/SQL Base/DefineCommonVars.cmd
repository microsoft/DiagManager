@ECHO OFF

REM PSSDIAG allows custom tasks to define variables, or tokens, that can be used in custom tasks just like 
REM environment variables.  This batch file is used to define several variables that can be used in other 
REM tasks. 
REM 
REM There are two ways in which PSSDIAG variables are more flexible than environment variables: 
REM 1. They can be used in SQL scripts (use a .TEM extension for the script file to tell PSSDIAG to search 
REM    the script for variables to replace. 
REM 2. A single PSSDIAG variable can have multiple values.  If a multi-valued variable is used in a task 
REM    definition, PSSDIAG automatically launches it once for each value associated with the variable. 
REM    This works the same as some of the built-in variables that PSSDIAG knows about automatically, like 
REM    %instance%.  If you were to use %instance% in a task, PSSDIAG will run that task one time for each 
REM    SQL instance installed on the machine, substituting the appropriate instance name for each 
REM    execution. 
REM 
REM The syntax to define a variable is the following: 
REM    ;%newvariable%=!!commandtorun!!
REM 
REM For example, this group includes the following task definition: 
REM    ;%SQL80TOOLSPATH%=!!DefineCommonVars.CMD SQL80TOOLSPATH!!
REM 
REM This tells PSSDIAG to run the command "DefineCommonVars.CMD SQL80TOOLSPATH". The value(s) to be 
REM associated with the variable (in this case, SQL 2000's shared tools path) is echo'ed to stdout. 
REM 

GOTO %1
GOTO :eof


REM ------------------------------
:REAL_PROCESSOR_ARCHITECTURE
REM 32-bit apps running in WoW64 get a modified environment.  %PROCESSOR_ARCHITECTURE% is automatically changed 
REM to "X86", and a new environment variable called %PROCESSOR_ARCHITEW6432% is added to store the actual processor 
REM type (either "IA64" or "AMD64").  There are cases where we want to know the actual CPU architecture (for 
REM example, to launch the appropriate native version of a data collection utility). 
IF DEFINED PROCESSOR_ARCHITEW6432 (
  SET REAL_PROCESSOR_ARCHITECTURE=%PROCESSOR_ARCHITEW6432%
  ECHO %PROCESSOR_ARCHITEW6432%
) ELSE (
  SET REAL_PROCESSOR_ARCHITECTURE=%PROCESSOR_ARCHITECTURE%
  ECHO %PROCESSOR_ARCHITECTURE%
)
GOTO :eof



REM ------------------------------
:ALL_PROGRAMFILES
REM Outputs all Program Files directories on the machine (e.g. C:\Program Files and C:\Program Files(x86))

REM Running in WoW64 on a 64-bit machine
IF "%ProgramW6432%" NEQ "" SET PRIMARY_PROGRAMFILES=%ProgramW6432%

REM Running on a 32-bit machine or 64-bit with a 64-bit environment
IF "%ProgramW6432%"=="" SET PRIMARY_PROGRAMFILES="%ProgramFiles%"

IF "%ProgramFiles%" NEQ "" ECHO %ProgramFiles%
IF "%ProgramW6432%" NEQ "" ECHO %ProgramW6432%& GOTO :eof
IF "%ProgramFiles(x86)%" NEQ "" ECHO %ProgramFiles(x86)%

GOTO :eof


REM ------------------------------
:ALL_COMMONPROGRAMFILES
REM Outputs all Program Files\Common Files directories on the machine

REM Running in WoW64 on a 64-bit machine
IF "%CommonProgramW6432%" NEQ "" SET PRIMARY_COMMONPROGRAMFILES=%CommonProgramW6432%

REM Running on a 32-bit machine or 64-bit with a 64-bit environment
IF "%CommonProgramW6432%"=="" SET PRIMARY_COMMONPROGRAMFILES="%CommonProgramFiles%"

IF "%CommonProgramFiles%" NEQ "" ECHO %CommonProgramFiles%
IF "%CommonProgramW6432%" NEQ "" ECHO %CommonProgramW6432%& GOTO :eof
IF "%CommonProgramFiles(x86)%" NEQ "" ECHO %CommonProgramFiles(x86)%

GOTO :eof


REM ------------------------------
:SQL80COMPATH
SET SQL80COMKEY=HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\80

CALL GetRegValue.CMD %1 "%SQL80COMKEY%" "SharedCode" > NUL
SET SQL80COMPATH=%GETREG_RESULT%

REM Add trailing backslash if not present at end of the file path. 
if (%SQL80COMPATH:~-1%) NEQ (\) set SQL80COMPATH=%SQL80COMPATH%\
ECHO %SQL80COMPATH%
GOTO :eof


REM ------------------------------
:SQL80TOOLSPATH
SET SQL80TOOLSKEY=HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\80\Tools\ClientSetup

CALL GetRegValue.CMD %1 "%SQL80TOOLSKEY%" "SQLPath" > NUL
SET SQL80TOOLSPATH=%GETREG_RESULT%

REM Add trailing backslash if not present at end of the file path. 
if (%SQL80TOOLSPATH:~-1%) NEQ (\) set SQL80TOOLSPATH=%SQL80TOOLSPATH%\
ECHO %SQL80TOOLSPATH%
GOTO :eof


