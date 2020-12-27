++++++++++++++++++++++++++++++++
PSSDIAG DATA COLLECTION UTILITY
++++++++++++++++++++++++++++++++

This utility was created by Microsoft engineers to assist with diagnostic log collection when you are troubleshooting problems in Microsoft SQL Server.
This utility is a collection of shell scripts as well as TSQL scripts that collect various data points of interest for a troubleshooting scenario.
As you can imagine there are various pre-requisites to be able to perform this data collection in a reliable manner.

You can run only a single copy of PSSDIAG utility on a system. If you attempt to launch the second instance, it will provide you with warnings and exit.
All the scripts are tested against bash shell. Please launch the start and stop collector explicitly using /bin/bash
This utility can collect information and logs for SQL Server instances that are installed as host instance or as container instances.

Steps to configure and start data collection using PSSDIAG, you will need to (exec -it) into the mssql-server container under the current primary master pod and perform the below steps
1. Create a folder to store the collected information (for example: /var/opt/mssql/data/pssdiag). 
	  mkdir /var/opt/mssql/data/pssdiag
   If you are capturing extended events, this folder hierarchy needs r+x on the whole structure.
   Specifically on RHEL the /home/user folder does not have x permissions for all. 
      drwxr-xr-x    2 root root    6 Aug  4 15:31 pssdiag

2. Copy the pssdiag.tar to the folder /pssdiag. The Microsoft engineer might provide this tar file to you.
   If you do not have the pssdiag.tar file, you can obtain using the following commands:
   
      cd /var/opt/mssql/data/pssdiag
      sudo curl -L https://github.com/Microsoft/DiagManager/releases/download/BdcRel20201227/pssdiag.tar | sudo tar x
   
   Make sure to use the latest release that is available.

3. Using the command [ls -l] you can verify the files and you will see a collection of files with .sh, .scn, .conf and .sql files. The important ones we will be using to launch the data collection are shown below:
	-rwxrwxr-x 1 username groupname  12292 Dec 27 05:29 start_collector.sh
	-rw-rw-r-- 1 username groupname   2449 Dec 27 05:29 sql_perf.scn
	-rw-rw-r-- 1 username groupname   2445 Dec 27 05:29 static_collect.scn
	-rwxrwxr-x 1 username groupname   5748 Dec 27 05:29 stop_collector.sh
        
   In this folder, if any of the .sh files do not have the x attribute, please execute the following command to set the required attributes:
   
      chmod a+x *.sh

4. For each log collection scenario, there are specific information points that need to be collected. To simplify things, we created scenario files like sql_perf.scn and static_collect.scn to specify all logs configuration aspects. These scenario files will provide directives to the utility on what specific logs and data points need to be captured. You can open the .scn files using the cat command or vi editor and make necessary adjustments as you see fit. You will notice that each scenario file contains sections for OS and SQL log collections.
   Note: The default setting is to collect information about the host instance of SQL Server. If you need to collect information for the container instances, you need to enable that configuration parameter in the .scn file to specify the container name or ALL to indicate every sql container.

5. To Start the PSSDIAG utility you will use the start_collector.sh script and pass the scenario as parameter:
   Below you will find an example of this:
	sudo /bin/bash ./start_collector.sh sql_perf.scn

		Reading configuration values from config scenario file ./sql_perf.scn
		Starting pre-req checks
		Completed pre-req checks
		collecting information from sql instance on host : master-0
		Testing SQL Connectivity for host_instance with name master-0 and port 1533
			Enter SQL UserName: admin
			Enter User Password: 
			SQL Connectivity test suceeded...
			Collecting SQL Configuration information at startup...
			Starting SQL Perf Stats script as a background job....
			Starting SQL Performance counter script as a background job.... 
			Starting SQL Memory Status script as a background job.... 
			Creating helper stored procedures in tempdb from MSDiagprocs.sql
			Starting SQL trace collection...  
		Note: Please reproduce the problem now and then stop the data collection... 
		Note: Please save the output from the terminal while starting the collector... 
		Note: Performance collectors started in the background, run stop_collector.sh to stop the background collectors... 

6. Please review the information in the terminal for any errors or other messages. Please save this information and pass it on to the engineer if you are working with one. The utility gathers all the diagnostic logs into a /output sub-directory under the directory where you extracted all the scripts. For long term collections you can monitor this /output directory for size and growth.

7. Depending on the scenario for which you are collecting logs, you may have to just run the start_collector. In some cases where you are collecting logs and diagnostic infromation for a period of time, you have to stop the utility. The information in the script output from start_collector will indicate if you have to specifically stop the log collection.
   When you stop the log collection, it will terminate various background processes that were collecting information. You can review these processes using the PID from the files stoppids*. There is a set of configuration information collected during the stop collector phase.

   To stop the utility and log collection, use the following command:
	sudo /bin/bash ./stop_collector.sh
	
		Terminating the following Background processes that were collecting sql data... Please wait.
		<>
		Terminating the following Background processes that were collecting os data... Please wait.
		<>
		Reading configuration values from Config file ./pssdiag_collector.conf
		Collecting Machine configuration...
		Collecting sqlservr process configuration... PID = 1722
		Collecting sqlservr process configuration... PID = 1822
		<>
		collecting sql instance logs from host instance
		collecting information from sql instance on host : master-0
		Testing SQL Connectivity for host_instance with name master-0 and port 1533
				Enter SQL UserName: admin
				Enter User Password: 
				SQL Connectivity test suceeded...
				Collecting SQL Configuration Snapshot at Shutdown...
				Stopping SQL Trace Collection if started...
				Collecting SQL AlwaysOn configuration at Shutdown...
				Collecting SQL Query Store information at Shutdown...
		============ Creating a compressed archive of all log files ===========
		***Data collected is in the file output_master-0_12_27_2020_17_13.tar.bz2 ***

8. Please upload this zip file to the engineer you are working with. It is a compressed archive of the /output directory which has all the diagnostic logs.


