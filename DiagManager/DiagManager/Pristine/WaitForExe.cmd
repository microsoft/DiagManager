@ECHO OFF
rem Example usage to wait until MSInfo32.EXE has finished running: 
rem       WaitForExe.cmd MSINFO32.EXE

:top
tlist | findstr -I -C:"%*" | findstr -V -I -C:"cmd.exe"
if (%errorlevel%)==(0) (
  rem Keep looping until the process is no longer running. 
  sleep 3
  goto top
)
