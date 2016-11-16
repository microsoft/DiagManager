@echo off

rem -------------------------------------------------------------------------------
Rem Setup the variables needed here to be used in the PSSLooksAlive batch process
rem
rem SERVERNAME=Servername/InstanceName for the SQL Server on which you are 
rem     trying to run the PSSLooksAlive
rem
rem SECURITY=Security Setting to be used (should have SYSADMIN rights), typically
rem     either "-E" or "-Usa -P<sapassword>"
rem
rem PSSLOOKSALIVEFILEPATH=Full File path for the PSSLooksAlive files. The 
rem PSSLooksAlive files should be extracted to this location.  This is also where
rem all PSSLooksAlive logs and the userdump will be captured, so the directory 
rem should have sufficient disk space for a full userdump of sqlservr.exe. 
rem -------------------------------------------------------------------------------


rem -- Uncomment the line below to use integrated security...
set SECURITY=-E
rem -- or uncomment this line to log in with sa (be sure to specify the password). 
rem set SECURITY=-Usa -Pmypassword


set SERVERNAME=.


set PSSLOOKSALIVEFILEPATH=C:\temp\psslooksalive\
