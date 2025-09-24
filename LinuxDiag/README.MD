# PSSDiag for SQL Server Linux
This utility was created by Microsoft engineers to assist with diagnostic log collection when you are troubleshooting problems in Microsoft SQL Server.
This utility is a collection of shell scripts as well as TSQL scripts that collect various data points of interest for a troubleshooting scenario.
As you can imagine there are various pre-requisites to be able to perform this data collection in a reliable manner.


## Supported Products
1. SQL Server running on a Linux machine (Host instance)
2. SQL Server container running in Docker (Container instance)
3. SQL Server container running in Kubernetes (Container instance)

## Prerequisites
You need to have the ability to execute these scripts with elevated permissions using the sudo command, as many data points require administrator-level access. You must be able to connect to the SQL Server instance using sysadmin credentials.

For all deployments types **sqlcmd** is required, its part of **mssql-tools** or **mssql-tools18**. For more details, refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools).
- for Docker and host, it must be installed on the host machine. 
- For Kubernetes, it must be installed directly on the SQL container.

	- **sqlcmd:**, use the following commands based on your distribution:
		- For RHEL:`sudo yum install mssql-tools18` or `sudo yum install mssql-tools`
		- For Ubuntu:`sudo apt install mssql-tools18` or `sudo apt install mssql-tools`
		- For SUSE:`sudo zypper install mssql-tools18` or `sudo zypper install mssql-tools`

Several Linux commands and utilities are necessary for data collection. **sysstat**, **iotop**, **lsof** and **bzip2**
- For Docker and host, these tools must be installed on the host machine.
- for Kubernetes, these commands and utilities are not applicable.
  
	- **sysstat:**, use the following commands based on your distribution:
		- For RHEL: `sudo yum install sysstat`
		- For Ubuntu: `sudo apt-get install sysstat`
		- For SUSE: `sudo zypper install sysstat`
		- More details can be found on [GitHub](https://github.com/sysstat/sysstat).

	- **iotop:**, use the following commands based on your distribution:
		- For RHEL: `sudo yum install iotop`
		- For Ubuntu: `sudo apt-get install iotop`
		- For SUSE: `sudo zypper install iotop`

	- **lsof:**, use the following commands based on your distribution:
		- For RHEL: `sudo yum install lsof`
		- For Ubuntu: `sudo apt-get install lsof`
		- For SUSE: `sudo zypper install lsof`

	- **bzip2:**, use the following commands based on your distribution:
		- For RHEL: `sudo yum install bzip2`
		- For Ubuntu: `sudo apt install bzip2`
		- For SUSE: `sudo zypper install bzip2`
  
When you launch the PSSDIAG utility, it checks for these prerequisites and notifies you of any missing commands or utilities. If you don't have all these tools, we may only be able to collect partial diagnostic logs, leading to potentially inconclusive results. Depending on your Linux operating system, you might need to register with the OS vendor to install all the required utilities. Seek assistance from your system administrator to complete these tasks.

## Scenario Files and Usage Information
You can run only a single copy of PSSDIAG utility on a system. If you attempt to launch the second instance, it will provide you with warnings and exit.
All the scripts are tested against bash shell. Please launch the start and stop collector explicitly using /bin/bash
This utility can collect information and logs for SQL Server instances that are installed as host instance or as container instances.

For each log collection scenario, there are specific information points that need to be collected. To simplify things, we created scenario files to specify all logs configuration aspects. These scenario files will provide directives to the utility on what specific logs and data points need to be captured. You can open the .scn files using the cat command or vi editor and make necessary adjustments as you see fit. You will notice that each scenario file contains sections for OS and SQL log collections.

Please review the information in the terminal for any errors or other messages. The utility gathers all the diagnostic logs into a /output sub-directory under the directory where you extracted all the scripts. For long term collections you can monitor this /output directory for size and growth.

Depending on the scenario for which you are collecting logs, you may have to just run the start_collector. In some cases where you are collecting logs and diagnostic information for a period of time, you have to stop the utility. The information in the script output from start_collector will indicate if you have to specifically stop the log collection.When you stop the log collection, it will terminate various background processes that were collecting information. You can review these processes using the PID from the files stoppids*. There is a set of configuration information collected during the stop collector phase.


This is list of the available scenario:

when running PSSDiag from host machine, PSSDiag will collect information from both host and container instances using one of the following scenarios:

```
+---+-----------------------------------+------------------------------------------------------------------------------+
|No |Scenario file                      |Description                                                                   |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 1 |scenario_static.scn                |Passive data collection approach,focusing solely on copying standard logs from|
|   |                                   |host OS and SQL without collecting any performance data. (Default)            |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 2 |scenario_sql_perf_minimal.scn      |Collects minimal performance data from SQL without extended events            |
|   |                                   |suitable for extended use.                                                    |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 3 |scenario_sql_perf_lite.scn         |Collects lightweight performance data from SQL and host OS,                   |
|   |                                   |suitable for extended use.                                                    |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 4 |scenario_sql_perf_general.scn      |Collects general performance data from SQL and host OS, ideal for             |
|   |                                   |15 to 20-minute collection periods, covering most scenarios.                  |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 5 |scenario_sql_perf_detailed.scn     |Collects detailed performance data at statement level, Use with Caution       |
|   |                                   |may impact server performance due to overhead.                                |
+---+-----------------------------------+------------------------------------------------------------------------------+
```
In the case when SQL container is deployed to Kubernetes, you can run PSSDiag from within the container collect information from the container using one of the following scenarios:
```
+---+-----------------------------------+------------------------------------------------------------------------------+
|No |Scenario file                      |Description                                                                   |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 1 |scenario_static_kube.scn           |Passive data collection approach,focusing solely on copying standard logs     |
|   |                                   |from SQL without collecting any performance data. (Default)                   |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 2 |scenario_sql_perf_minimal_kube.scn |Collects minimal performance data from SQL without extended events            |
|   |                                   |suitable for extended use.                                                    |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 3 |scenario_sql_perf_lite_kube.scn    |Collects lightweight performance data from SQL, suitable for extended use.    |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 4 |scenario_sql_perf_general_kube.scn |Collects general performance data from SQL, Ideal for 15 to 20-minute         |
|   |                                   |collection periods, covering most scenarios.                                  |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 5 |scenario_sql_perf_detailed_kube.scn|Collects detailed performance data at statement level, Use with Caution       |
|   |                                   |may impact server performance due to overhead.                                |
+---+-----------------------------------+------------------------------------------------------------------------------+
```
**Note**
To review which information is being collected in a scenario, please open the .scn file and check its settings.

You can create a custom scenario file by copying an existing one and modifying the settings as needed. Ensure the file is located in the same directory as PSSDiag, and pass it as the first argument when running the start script.

## Authentication Modes
PSSDiag can use one of the following Authentication Modes when connecting to SQL server
```
+---+-----------------------------------+------------------------------------------------------------------------------+
|No |Authentication Mode                |Description                                                                   |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 1 |SQL                                |Use SQL Authentication. (Default)                                             |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 2 |AD                                 |Use AD Authentication                                                         |
+---+-----------------------------------+------------------------------------------------------------------------------+
| 3 |NONE                               |Allows to select the method per instance when multiple instances              |
|   |                                   |host instance and container instance/s running on the same host,              |
|   |                                   |not applicable for sql running on Kubernetes                                  |
+---+-----------------------------------+------------------------------------------------------------------------------+
```
**Note**
If you want to use AD Authenticaiton Mode, run kinit with AD user that is allowed to connect to sql server before running PSSDiag.

```
sudo kinit user@DOMAIN.COM
```

**Note**
when running PSSDiag from inside the container (the case of Kubernetes) you will only have 'SQL' Authentication Mode.

## PSSDiag Scripts Arguments 
PSSDiag has the following argument s

Starting script `start_collector.sh` accepts 3 arguments 
- Scenario file: Valid options include any of the scenario files listed above, or a custom scenario you configure with the necessary settings. If any required setting is omitted, it will automatically default to NO or the lightest-weight value applicable for that setting.
- Authentication Mode: Valid options are SQL, AD, or NONE. If not specified, PSSDiag will prompt you to choose an authentication mode.
- perfstat file, Valid options are sql_perf_stats.sql and sql_perf_stats_lite.sql. If not specified, PSSDiag will default to sql_perf_stats.sql.

Stopping script `stop_collector.sh` accepts 1 argument
- Authentication Mode: Valid options are SQL, AD, or NONE. If not specified, PSSDiag will prompt you to choose an authentication mode.

**Examples**

Start without passing any arguments, PSSDiag will ask you which Scenario and Authentication Mode to use.

```
sudo /bin/bash ./start_collector.sh
```

Passing Scenario and Authentication Mode to Start script.

```
sudo /bin/bash ./start_collector.sh 'scenario_static_collect.scn' 'SQL'
```

Passing Authentication Mode argument only to Start script, PSSDiag will ask you which Scenario to use.

```
sudo /bin/bash ./start_collector.sh '' 'AD'
```

Passing Authentication Mode argument to Stop script

```
sudo ./stop_collector.sh 'SQL'
```
**Important Note:** 
when running on host, If your Intention to run the following run scenarios:

	scenario_sql_perf_detailed.scn
	scenario_sql_perf_general.scn

the defaults are `COLLECT_HOST_SQL_INSTANCE=YES` and `COLLECT_CONTAINER=ALL` assuming most deployments are either just single host instance or single container instance, the tools will be able find the instance whether its host or container and get the data.

however, If you have multiple instances running on the **same machine**, whether as a host instance or multiple Docker instances, you need to adjust the `COLLECT_HOST_SQL_INSTANCE` and `COLLECT_CONTAINER` settings in  **scenario_sql_perf_general.scn** or **scenario_sql_perf_detailed.scn** scenario files, For example:

- to collect from only host instance, set `COLLECT_HOST_SQL_INSTANCE=YES` and `COLLECT_CONTAINER=NO` 
- to collect from specific container instance, set `COLLECT_HOST_SQL_INSTANCE=NO` and `COLLECT_CONTAINER=[your_container_instance_name]`
- to collect from all container instances, then adjust these setting to `COLLECT_HOST_SQL_INSTANCE=NO` and `COLLECT_CONTAINER=ALL`
- To collect data from all instances, both host and container instances, use the default settings `COLLECT_HOST_SQL_INSTANCE=YES` and `COLLECT_CONTAINER=ALL`

## Downloading and Executing PSSDiag 
### Downloading PSSDiag
- Navigate to releases using the following link https://github.com/microsoft/DiagManager/releases?q=Linux&expanded=true 
- Expand Assests section
- Download `pssdiag_<version>.tar` 


### Preparing PSSDiag for Execution   
1. you will need to copy `pssdiag_<version>.tar` into folder

	**Note:** if you are capturing extended events the folder hierarchy needs r+x on the whole structure, Different Linux distributions do not allow x permissions on /home/user folder. for example run pssdiag from /tmp or /var/tmp folders
	
	```bash
	drwxr-xr-x    2 root root    6 Aug  4 15:31 pssdiag
	```
	
2. extract the content to /tmp/pssdiag using `tar -xvf pssdiag_<version>.tar -C /`
3. Make sure all *.sh has x attribute, if needed run `chmod a+x *.sh`

### Starting PSSDiag

**Note:** to allow AD Authentication collectors to collect kvno and klist of service accounts and ketytabs, you need to run the following before running pssdiag.

```
sudo kinit user@DOMAIN.COM
```

Execute this command to start PSSDiag. It will guide you through Selecting a scenario and Authentication Mode. Please keep an eye on the screen throughout the execution.

```
sudo /bin/bash ./start_collector.sh
``` 

### Stopping PSSDiag
if you are using of the Scenarios that collects performace data we need to stop PSSDiag after reproducing the issue.

Execute this command to stop PSSDiag. Please keep an eye on the screen throughout the execution for any login request.

```
sudo /bin/bash ./stop_collector.sh
```
Please upload the produced compressed output file to the engineer you are working with. the produced compressed file is a compressed archive of the **/output** directory which has all the diagnostic logs.

**Note** executing 'stop_collector.sh' is not requried for `scenario_static_collect.scn` Scenario.


## Capture logs from SQL Container Instance Deployed in Kubernetes
1. you will need to copy `pssdiag_<version>.tar` into the sql server container using "kubectl cp", in case sql server is part of always on setup, then to copy it to the primary
2. "kubectl exec... bash" into master POD
3. extract the content using `tar -xvf pssdiag_<version>.tar`
4. Make sure all *.sh has x attribute using `chmod a+x *.sh`

### Starting PSSDiag 
Execute this command to start PSSDiag. It will guide you through Selecting a scenario

```
/bin/bash ./start_collector.sh
```

### Stopping PSSDiag
if you are using of the Scenarios that collects performace data we need to stop PSSDiag after reproducing the issue.

```
/bin/bash ./stop_collector.sh
```

**Note** executing 'stop_collector.sh' is not requried for `scenario_static_collect_kube.scn` Scenario.

Please upload this zip file to the engineer you are working with. It is a compressed archive of the /output directory which has all the diagnostic logs.


# License Agreement
[MIT License](/license.md)
