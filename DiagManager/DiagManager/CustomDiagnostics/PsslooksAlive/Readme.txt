This tool can be used in 3 ways:
a. Use it on a Server(which is currently running) to capture a userdump for FUTURE HANGS
b. Use it on a Server which is already in a HUNG state and you are trying to get a Userdump for the server
c. Use it from PSSDIAG to capture a userdump for FUTURE HANGS

=====OPTION A: GET USERDUMP FOR FUTURE HANG OF THE SERVER===========================
0. This needs to be run on the server LOCALLY.
1. Create a new folder, named "PSSLooksAlive" on a drive which has more than 3GB of space on the server. (lets say "c:\PSSLooksAlive")
2. Unzip the PssLooksAlive.zip attached with this Email to the "PSSLooksAlive" directory.
3. Edit(DO NOT DOUBLECLICK, INSTEAD RIGHT CLICK AND EDIT) the SetupVars.bat file to change the following variables to match your environment:

SERVERNAME - Servername\InstanceName for the SQL Server on which you are trying to run the PSSLooksAlive
SECURITY - Security setting to be used, e.g. "SECURITY=-E" or "SECURITY=-Usa -Pmypassword" (should have SYSADMIN rights)
PSSLOOKSALIVEFILEPATH - PSSLOOKSALIVEFILEPATH=Full File path for the PSSLooksAlive files


4. Run the StartPSS.bat file  


=====OPTION B: GET USERDUMP FOR SERVER WHICH IS ALREADY IN A HUNG STATE=============
0. This needs to be run on the server LOCALLY.
1. Create a new folder, named "PSSLooksAlive" on a drive which has more than 3GB of space on the server. (lets say "c:\PSSLooksAlive")
2. Unzip the PssLooksAlive.zip attached with this Email to the "PSSLooksAlive" directory.
3. Edit(DO NOT DOUBLECLICK, INSTEAD RIGHT CLICK AND EDIT) the ManualUserDump.bat file to make the following change for the Full path for the PSSLooksAlive files directory(with one created in Step 1)

Change: 
	SET PSSLOOKSALIVEFILEPATH=c:\PSSLooksAlive
	to
	SET PSSLOOKSALIVEFILEPATH=<YourFullFilePathToPSSLOOKSALIVEFILES>


4. Run the ManualUserDump.bat file (by passing in the ProcessID for the instance of SQL Server). If the ProcessID is not supplied, then it will attempt to get a userdump for the first SQLSERVR.exe it finds on the system(note that with multiple instances, more than one sqlservr.exe may exist)


=====OPTION C: GET USERDUMP FOR FUTURE HANGS FROM PSSDIAG===========================
0. PSSDIAG must be run on the server LOCALLY.
1. Launch PSSDIAG_SETUP.EXE.  Check the "Startup Utilities" checkbox, and select "PSSLooksAlive.TXT" in 
   the drop-down listbox. 
2. Check the "Shutdown Utilities" checkbox, and select "PSSLooksAlive_cleanup.TXT" in the drop-down listbox. 
3. Copy the entire contents of PSSLooksAlive.zip to a new folder <PSSDIAGDIR>\PSSDIAG\PSSLooksAlive so that 
   it will be compressed into PSSD.EXE with all the other PSSDIAG files to send to the customer. 



=====Internal workings of the Batch files:==========================================

StartPSS.bat working:
1. It makes a connection to the server and then retrieves the processid for SQL Server using the SERVERPROPERTY('processid'). It then uses the SERVERNAME & PROCESSID to run the LooksAliveBatch.sql file
2. It makes a OSQL connection USING the ServerName from SetupVars.bat with 15sec LoginTimeout and 15sec QueryTimeout
3. If successful with making a connection, it will execute the query mentioned in LooksAliveBatch.sql (simple select statement from master..sysdatabases). 
4. If it encounters any error (connection/query error), it will initiate a FIRSTRETRY, which does the same thing as connecting using the servername with 15sec LoginTimeout and 15sec QueryTimeout. If on firstretry, it is able to connect and query, it will go back to its main loop, however if firstretry also fails, it will initiate a SecondRetry.
5. SecondRetry does the exact same thing as firstretry. If secondretry fails, it will call ThirdRetry
6. ThirdRetry will also attempt to connect and execute the query with same parameters. If the thirdretry also fails, then it will invoke the AutoUserDump.bat file
7. AutoUserDump.bat will attach to SQL Server non-invasively using the Process ID retreived earlier(from step1) and then initiate a userdump by issuing a ".dump" command as documented in NTSD.INI. It is critical that SetupVars.bat be edited to reflect the correct path(PSSLOOKSALIVEPATH) for the NTSD.INI, else this step may hang and not provide any userdump.
g. Once the Userdump is completed, it will quit WITHOUT stopping SQL Server.


NOTE:
If for some reason the Automatic batch files do not generate the Userdump, you can always run the ManualUserDump.bat manually to initiate the userdump for SQL by passing in the ProcessID for SQL Server. If no processid is specified, then it will attempt to get a userdump for the first SQLSERVR.exe it finds on the system (note that with multiple instances, more than one sqlservr.exe may exist)

The processid can be obtained by one of the following methods:
a. From the TOP of the SQL Server 2000 errorlog for the instance you need to run against
b. Tlist.exe: By running "tlist -s"
c. EnumProcs.exe: By running EnumProcs which shows the processid & the filepath for all the executables
