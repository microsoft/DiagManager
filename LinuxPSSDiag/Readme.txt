Pre-requisites to run the Data collection:
- iotop  ( sudo yum install iotop / sudo apt-get install iotop )
- systat ( sudo yum install systat / sudo apt-get install systat )
- sqlcmd  - https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools 
You can run only a single copy of pssdiag on a system.
All the scripts are tested against bash shell. Please launch the start and stop collector explicitly using /bin/bash
You have to launch the data collection with sudo priviliges since many data points we need to collect require elevated permissions.

Steps to configure and start data collection:
1. Create a folder say /mnt/data/pssdiag.  If capturing extended events in particular, that folder heirarcy has to have r+x on the whole structure.
   Specifically on RHEL the /home/user folder does not have x permissions for all. 
      drwxr-xr-x    2 root root    6 Aug  4 15:31 pssdiag

2. Copy the pssdiag.tar.gz into the linux box in a folder  /pssdiag
3. Extract the files as follows in that folder created
	[denzilr@sqlredhat pssdiag]$ tar -xvf pssdiag.tar


4. Verify the files and you will see the following list of .sh and .sql files. 
	root@SKB-VMD-UBU:/home/SureshKaVM/pssdiag# ls -l
	total 200
	-rw-rw-r-- 1 SureshKaVM SureshKaVM  1283 Jul 10 03:14 Changelog.txt
	-rwxrw-r-- 1 SureshKaVM SureshKaVM  2403 Jun 15 19:39 check_pre_req.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM   394 Jun 15 19:39 collect_cpu_stats.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM  2054 Jul  7 21:18 collect_dumps.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM   397 Jun 15 19:39 collect_io_stats.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM  3509 Jun 15 19:39 collect_machineconfig.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM   508 Jun 15 19:39 collect_mem_stats.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM   248 Jun 15 19:39 collect_network_stats.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM  1392 Jul  6 16:51 collect_os_logs.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM   312 Jun 15 19:39 collect_process_stats.sh
	-rwxr--r-- 1 SureshKaVM SureshKaVM  1589 Jul  7 21:20 collect_sql_logs.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM    54 Jun 15 19:39 create_tar.sh
	-rw-rw-r-- 1 SureshKaVM SureshKaVM   152 Jun 15 19:39 my_custom_collector.sql
	-rwxrw-r-- 1 SureshKaVM SureshKaVM    30 Jun 15 19:39 pssdiag_anchor.sh
	-rw-rw-r-- 1 SureshKaVM SureshKaVM   311 Jul 10 01:52 pssdiag_collector.conf
	-rw-rw-r-- 1 SureshKaVM SureshKaVM   189 Jun 15 19:39 pssdiag_importer.conf
	-rw-rw-r-- 1 SureshKaVM SureshKaVM  1717 Jun 15 19:39 pssdiag_xevent.sql
	-rw-rw-r-- 1 SureshKaVM SureshKaVM   442 Jul 10 01:59 pssdiag_xevent_start.sql
	-rw-rw-r-- 1 SureshKaVM SureshKaVM   394 Jun 15 19:39 pssdiag_xevent_start.template
	-rw-rw-r-- 1 SureshKaVM SureshKaVM   425 Jun 15 19:39 pssdiag_xevent_stop.sql
	-rw-rw-r-- 1 SureshKaVM SureshKaVM  5231 Jun 15 19:39 Readme.txt
	-rw-rw-r-- 1 SureshKaVM SureshKaVM 31751 Jun 15 19:39 SQL_Configuration.sql
	-rw-rw-r-- 1 SureshKaVM SureshKaVM 15967 Jun 15 19:39 SQL_DMV_Snapshots.sql
	-rw-rw-r-- 1 SureshKaVM SureshKaVM  8872 Jun 15 19:39 SQL_Mem_Stats.sql
	-rw-rw-r-- 1 SureshKaVM SureshKaVM   371 Jul 10 01:59 SQL_Performance_Counters.sql
	-rw-rw-r-- 1 SureshKaVM SureshKaVM 27845 Jun 15 19:39 SQL_Perf_Stats.sql
	-rwxrw-r-- 1 SureshKaVM SureshKaVM 12221 Jul 10 01:58 start_collector.sh
	-rwxrw-r-- 1 SureshKaVM SureshKaVM  6060 Jul 10 02:02 stop_collector.sh

     If you notice that the *.sh files are not having the execute permission [x] then execute the command: 
     chmod a+x *.sh

5. Before you start the data collection review the configuration file to ensure the data you require will be collected. There is a configuration file that currently controls the data collection: pssdiag_collector.conf file. Specify one of the allowed values for each configuration option.

[root@sqlredhat pssdiagfinal]# cat pssdiag.conf
COLLECT_CONFIG=YES	    ===> Collects SQL configuration and machine configuration. Specify YES or NO.
COLLECT_PERFSTATS=YES	    ===> This collects SQL Server performance statistics , executing requests, snapshots of waitstats etc. Specify YES or NO.
COLLECT_EXTENDED_EVENTS=NO  ===> Turned off by default, this is configured for batch completed and RPC completed only. Specify YES or NO.
COLLECT_SQL_COUNTERS=YES    ===> Collects snapshots of sys.dm_os_performance_counters. Specify YES or NO.
SQL_COUNTERS_INTERVAL=10    ===> Interval at which sys.dm_os_performance_counters is collected. Specify value in seconds.
COLLECT_OS_COUNTERS=YES	    ===> Collects Mpstats, iostats, sar, OS level counters. Specify YES or NO.
OS_COUNTERS_INTERVAL=10     ===> Interval at which cpu/io/memory/network metrics are collected. Specify value in seconds.
COLLECT_LOGS=YES	    ===> Gets all SQL errorlogs, .xel files under the log folder ( system health etc), also gets OS logs. Specify YES or NO.
COLLECT_SQL_MEM_STATS=NO    ===> Collects various memory related DMVS. Specify YES or NO.
CUSTOM_COLLECTOR=NO         ===> If you want any other custom collection, set this to YES and change the SQL_Custom_Script.sql file to include your queries.  
COLLECT_HOST=YES            ===> Collect information about the SQL Server instance running on this host machine. Specify YES or NO.
COLLECT_CONTAINER=NO        ===> Collect information about the SQL Server instances running inside containers. Specify ALL or <container name> or NO.
COLLECT_SQL_DUMPS=NO        ===> Indicate whether to gather and include all SQL Dumps and core dumps into the final compressed file. Specify YES or NO.

6. To Start the collector:
 
[denzilr@sqlredhat pssdiagfinal]# sudo bash start_collector.sh
	Starting pre-req checks
	Completed pre-req checks
	Output directory {/home/denzilr/repos/pssdiag/output}  exists.. Do you want to overwrite (Y/N) ?Y
	Reading configuration values from Config file ./pssdiag.conf
	Collecting Machine configuration... output file: /home/denzilr/repos/pssdiag/output/denzilrredhat_machineconfig.info
	Testing SQL Connectivity ...
	Enter SQL UserName: sa
	Enter User Password:
	SQL Connectivity test suceeded...
	Starting PerfStats script as a background job.... Run stopcollector.sh to stop
	Starting Performance counter  script as a background job.... Run stopcollector.sh to stop
	Collecting Configuration information at startup...
	Starting io stats collector as a background job...Run stopcollector.sh to stop
	Starting cpu stats collector as a background job...Run stopcollector.sh to stop
	Starting memory collector as a background job...Run stopcollector.sh to stop
	Starting process collector as a background job...Run stopcollector.sh to stop
	Starting network stats  collector as a background job...Run stopcollector.sh to stop
  Please reproduce the problem now and then stop the data collection...
  Note: Performance collectors started in the background, run stopcollector.sh to stop the background collectors...

7. To Stop the collector:
	[denzilr@sqlredhat pssdiagfinal]# sudo bash stop_collector.sh
	...
	..
	***Data collected is in the file output_machinename_03_22_2017_15_06.tar.gz ***

8. You will get an zipped folder in the directory created called output_machineName_datetime.tar.gz as indicated in Step above.



