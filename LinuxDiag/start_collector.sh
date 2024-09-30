#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

# defining all functions upfront

sql_collect_perfstats()
{
        if [[ $COLLECT_PERFSTATS == [Yy][eE][sS] ]] ; then
                #Start regular PerfStats script as a background job
                echo -e "$(date -u +"%T %D") Starting SQL Perf Stats script as a background job...." | tee -a $pssdiag_log
                `$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Perf_Stats.sql" -o"$outputdir/${1}_${2}_SQL_Perf_Stats.out"` &
                mypid=$!
                #printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.txt
		sleep 5s
                pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.txt

				echo -e "$(date -u +"%T %D") Starting SQL Linux Stats script as a background job...." | tee -a $pssdiag_log
                `$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Linux_Stats.sql" -o"$outputdir/${1}_${2}_SQL_Linux_Stats.out"` &
                mypid=$!
                #printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.txt
		sleep 5s
                pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.txt
        fi
}

sql_collect_counters()
{
        if [[ $COLLECT_SQL_COUNTERS == [Yy][eE][sS] ]] ; then
                #Start sql performance counter script as a background job
                #Replace Interval with SED
                sed -i'' -e"2s/.*/SET @SQL_COUNTER_INTERVAL = $SQL_COUNTERS_INTERVAL/g" SQL_Performance_Counters.sql
                echo -e "$(date -u +"%T %D") Starting SQL Performance counter script as a background job.... " | tee -a $pssdiag_log
                `$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Performance_Counters.sql" -o"$outputdir/${1}_${2}_SQL_Performance_Counters.out"` &
                mypid=$!
                #printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.txt
		sleep 5s
                pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.txt
        fi
}


sql_collect_memstats()
{
        if [[ $COLLECT_SQL_MEM_STATS == [Yy][eE][sS] ]] ; then
                #Start SQL Memory Status script as a background job
                echo -e "$(date -u +"%T %D") Starting SQL Memory Status script as a background job.... " | tee -a $pssdiag_log
                `$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Mem_Stats.sql" -o"$outputdir/${1}_${2}_SQL_Mem_Stats.out"` &
                mypid=$!
                #printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.txt
		sleep 5s
                pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.txt
        fi
}

sql_collect_custom()
{
        if [[ $CUSTOM_COLLECTOR == [Yy][eE][sS] ]] ; then
                #Start Custom Collector  scripts as a background job
                echo -e "$(date -u +"%T %D") Starting SQL Custom Collector Scripts as a background job.... " | tee -a $pssdiag_log
                for filename in my_custom_collector*.sql; do
                   `$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"${filename}" -o"$outputdir/${1}_${2}_${filename}_Output.out"` &
                    mypid=$!
                    #printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.txt
		    sleep 5s
                    pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.txt
                done
        fi
}

sql_collect_xevent()
{
        #start any XE collection if defined? XE file should be named pssdiag_xevent_.sql.
        if [[ $COLLECT_EXTENDED_EVENTS == [Yy][eE][sS]  ]]; then
                echo -e "$(date -u +"%T %D") Starting SQL Extended Events collection...  " | tee -a $pssdiag_log
                $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1)  -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"${EXTENDED_EVENT_TEMPLATE}.sql" -o"$outputdir/${1}_${2}_pssdiag_xevent.out"
                cp -f ./pssdiag_xevent_start.template ./pssdiag_xevent_start.sql
		if [[ "$2" == "host_instance" ]] || [[ "$2" == "instance" ]]; then
	                sed -i "s|##XeFileName##|${outputdir}/${1}_${2}_pssdiag_xevent.xel|" pssdiag_xevent_start.sql
		else
                    sed -i "s|##XeFileName##|/var/opt/mssql/log/${1}_${2}_pssdiag_xevent.xel|" pssdiag_xevent_start.sql
		fi
                /$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"pssdiag_xevent_start.sql" -o"$outputdir/${1}_${2}_pssdiag_xevent_start.out"
        fi
}

sql_collect_trace()
{
        #start any SQL trace collection if defined? 
        if [[ $COLLECT_SQL_TRACE == [Yy][eE][sS]  ]]; then
		echo -e "$(date -u +"%T %D") Creating helper stored procedures in tempdb from MSDiagprocs.sql" >> $pssdiag_log
		$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1)  -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"MSDiagProcs.sql" -o"$outputdir/${1}_${2}_MSDiagprocs.out"
                echo -e "$(date -u +"%T %D") Starting SQL trace collection...  " | tee -a $pssdiag_log
                cp -f ./${SQL_TRACE_TEMPLATE}.template ./pssdiag_trace_start.sql
		if [[ "$2" == "host_instance" ]]; then
			sed -i "s|##TraceFileName##|${outputdir}/${1}_${2}_pssdiag_trace|" pssdiag_trace_start.sql
		else
			sed -i "s|##TraceFileName##|/var/opt/mssql/log/${1}_${2}_pssdiag_trace|" pssdiag_trace_start.sql
		fi
		$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"pssdiag_trace_start.sql" -o"$outputdir/${1}_${2}_pssdiag_trace_start.out"
        fi
}

sql_collect_config()
{
        #include whatever base collector scripts exist here
        echo -e "$(date -u +"%T %D") Collecting SQL Configuration information at startup..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Configuration.sql" -o"$outputdir/${1}_${2}_SQL_Configuration_Startup.out"
}

sql_collect_linux_snapshot()
{
        echo -e "$(date -u +"%T %D") Collecting SQL Linux Snapshot at Startup..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Linux_Snapshot.sql" -o"$outputdir/${1}_${2}_SQL_Linux_Snapshot_Startup.out"
}

sql_collect_perfstats_snapshot()
{
        echo -e "$(date -u +"%T %D") Collecting SQL Perf Stats Snapshot at Startup..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Perf_Stats_Snapshot.sql" -o"$outputdir/${1}_${2}_SQL_Perf_Stats_Snapshot_Startup.out"
}

# end of all function definitions

#################################
# start of main script execution
#################################
echo "" 

get_host_instance_status
get_container_instance_status
pssdiag_inside_container_get_instance_status

# check if user passed any parameter to the script 
scenario=${1,,}
authentication_mode=${2^^}

# if [[ -n "$scenario" ]]; then
# 	# Parameter processing from config scenario file scenario_<name>.conf in same directory
# 	# Read config files, if defaults are overwridden there, they will be adhered to
# 	# Config file values are  Key value pairs Example"  COLLECT_CONFIG=YES
# 	CONFIG_FILE="./${scenario}"
# 	echo "Reading configuration values from config scenario file $CONFIG_FILE" 
# 	if [[ -f $CONFIG_FILE ]]; then
# 		. $CONFIG_FILE
# 		cp -f ./${scenario} ./pssdiag_collector.conf
# 	else
# 		echo "" 
# 		echo "Error reading configuration file specified as input" 
# 		echo "Please verify you are using one of the following scenario files" 
# 		echo "" 
# 		ls -1 *.scn
# 		echo "" 
# 		exit 1
# 	fi
# fi

#Checks: make sure we have a valid scenario entered, we are running with system that has systemd
if [[ ! -z "$scenario" ]] && [[ "$is_instance_inside_container_active" == "NO" ]] && [[ "$scenario" != "static_collect.scn" ]] && [[ "$scenario" != "sql_perf_light.scn" ]] && [[ "$scenario" != "sql_perf_general.scn" ]] && [[ "$scenario" != "sql_perf_detailed.scn" ]]; then
	echo -e "\x1B[31mError is specifying a scenario (first argument passed to PSSDiag)\x1B[0m"
	echo "" 
	echo "Valid options are:" 
	echo "  static_collect.scn"
	echo "  sql_perf_minimal.scn"
	echo "  sql_perf_light.scn"
	echo "  sql_perf_general.scn"
	echo "  sql_perf_detailed.scn"
	echo "" 
	echo "if you are unsure what option to pass, just run 'sudo /bin/bash ./start_collector.sh' and PSSDiag will guide you" 
	echo "" 
	echo "exiting..." 
	echo "" 
	exit 1	
fi

#Checks: make sure we have a valid authentication entered, we are running with system that has systemd
if [[ ! -z "$authentication_mode" ]] && [[ "$is_instance_inside_container_active" == "NO" ]] && [[ "$authentication_mode" != "SQL" ]] && [[ "$authentication_mode" != "AD" ]] && [[ "$authentication_mode" != "NONE" ]]; then
	echo -e "\x1B[31mError in specifying authentication mode (second argument passed to PSSDiag)\x1B[0m"
	echo "" 
	echo "Valid options are:" 
	echo "  SQL"
	echo "  AD"
	echo "  NONE"
	echo "" 
	echo "if you are unsure what option to pass, just run 'sudo /bin/bash ./start_collector.sh' and PSSDiag will guide you" 
	echo "" 
	echo "exiting..." 
	echo "" 
	exit 1	
fi

#Checks: make sure we have a valid scenario entered, we are running with system that has no systemd
if [[ ! -z "$scenario" ]] && [[ "$is_instance_inside_container_active" == "YES" ]] && [[ "$scenario" != "static_collect_kube.scn" ]] && [[ "$scenario" != "sql_perf_light_kube.scn" ]] && [[ "$scenario" != "sql_perf_general_kube.scn" ]] && [[ "$scenario" != "sql_perf_detailed_kube.scn" ]]; then
	echo -e "\x1B[31mError is specifying a scenario (first argument passed to PSSDiag)\x1B[0m"
	echo "" 
	echo "Valid options are:" 
	echo "  static_collect_kube.scn"
	echo "  sql_perf_minimal_kube.scn"
	echo "  sql_perf_light_kube.scn"
	echo "  sql_perf_general_kube.scn"
	echo "  sql_perf_detailed_kube.scn"	
	echo "" 
	echo "if you are unsure what option to pass, just run '/bin/bash ./start_collector.sh' and PSSDiag will guide you" 
	echo "exiting..." 
	echo "" 
	exit 1	
fi

#Checks: make sure we have a valid authentication entered, we are running with system that has no systemd
if [[ ! -z "$authentication_mode" ]] && [[ "$is_instance_inside_container_active" == "YES" ]] && [[ "$authentication_mode" != "SQL" ]]; then
	echo -e "\x1B[31mError in specifying authentication mode (second argument passed to PSSDiag)\x1B[0m"
	echo "" 
	echo "Valid options are:" 
	echo "  SQL"
	echo "" 
	echo "if you are unsure what option to pass, just run '/bin/bash ./start_collector.sh' and PSSDiag will guide you" 
	echo "exiting..." 
	echo "" 
	exit 1	
fi

#if the scenario is valid, then use it for pssdiag_collector.conf
if [[ -n "$scenario" ]]; then
	# Parameter processing from config scenario file scenario_<name>.conf in same directory
	# Read config files, if defaults are overwridden there, they will be adhered to
	# Config file values are  Key value pairs Example"  COLLECT_CONFIG=YES
	CONFIG_FILE="./${scenario}"
	echo "Reading configuration values from config scenario file $CONFIG_FILE" 
	if [[ -f $CONFIG_FILE ]]; then
		. $CONFIG_FILE
		cp -f ./${scenario} ./pssdiag_collector.conf
	else
 		echo "" 
		echo "Error reading configuration file specified as input, make sure that $scenario exists" 
		exit 1
	fi
fi

#if scenario has not been passed and we are running with systemd system
if [[ -z "$scenario" ]] && [[ "$is_instance_inside_container_active" == "NO" ]]; then
	echo -e "\x1B[2;34m============================================ Select Run Scenario ===========================================\x1B[0m" 
	echo "Run Scenario's:"
	echo ""
	echo "Defines the level of data collection from OS and SQL whether they are host or container instance"
	echo ""
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo -e "|No |Run Scenario           |Description                                                                   |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 1 |static_collect.scn     |Passive data collection approach,focusing solely on copying standard logs from|"
	echo -e "|   |                       |the OS and SQL without collecting any performance data. \x1B[34m(Default)\x1B[0m             |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 2 |sql_perf_minimal.scn   |Collects minimal performance data from SQL without extended events            |"
	echo    "|   |                       |suitable for extended use.                                                    |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 3 |sql_perf_light.scn     |Collects lightweight performance data from SQL and the operating system,      |"
	echo    "|   |                       |suitable for extended use.                                                    |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 4 |sql_perf_general.scn   |Collects general performance data from SQL and the OS, suitable for           |"
	echo    "|   |                       |15 to 20-minute collection periods, covering most scenarios.                  |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 5 |sql_perf_detailed.scn  |Collects detailed performance data from SQL and the OS;avoid using this method|"
	echo    "|   |                       |for extended periods as it generates a large amount of data.                  |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo ""
	scn_user_selected=""
	while [[ ${scn_user_selected} != [1-5] ]]
	do
		read -r -p $'\e[1;34mSelect a Scenario [1-5] (Enter to select the default "static_collect.scn"): \e[0m' scn_user_selected
		scn_user_selected=${scn_user_selected:-1}
		if [[ ${scn_user_selected} == 1 ]]; then
			scenario="static_collect.scn"
		fi
		if [[ ${scn_user_selected} == 2 ]]; then
			scenario="sql_perf_minimal.scn"
		fi
		if [[ ${scn_user_selected} == 3 ]]; then
			scenario="sql_perf_light.scn"
		fi
		if [[ ${scn_user_selected} == 4 ]]; then
			scenario="sql_perf_general.scn"
		fi
		if [[ ${scn_user_selected} == 5 ]]; then
			scenario="sql_perf_detailed.scn"
		fi
		echo ""

		CONFIG_FILE="./${scenario}"
		#echo "Reading configuration values from config scenario file $CONFIG_FILE" 
		echo "Reading configuration values from config scenario file $CONFIG_FILE" 
		if [[ -f $CONFIG_FILE ]]; then
			. $CONFIG_FILE
			cp -f ./${scenario} ./pssdiag_collector.conf
		else
 			echo "" 
	 		echo "Error reading configuration file specified as input, make sure that $scenario exists" 
			exit 1
		fi
	done 
fi

#if authentication_mode has not been passed and we are running with systemd system
if [[ -z "$authentication_mode" ]] && [[ "$is_instance_inside_container_active" == "NO" ]]; then
	echo -e "\x1B[2;34m======================================== Select Authentication Mode ========================================\x1B[0m" 
	echo "Authentication Modes:"
	echo ""
	echo "Defines the Authentication Mode to use when connecting to SQL whether they are host or container instance"
	echo ""
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "|No |Authentication Mode    |Description                                                                   |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo -e "| 1 |SQL                    |Use SQL Athentication. \x1B[34m(Default)\x1B[0m                                              |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 2 |AD                     |Use AD Authentication                                                         |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 3 |NONE                   |Allows to select the method per instance when multiple instances              |"
	echo    "|   |                       |host instance and container instance/s running on the same host,              |"
	echo    "|   |                       |not applicable for sql running on Kubernetes                                  |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo ""
	auth_mode_selected=""
	while [[ ${auth_mode_selected} != [1-3] ]]
	do
		read -r -p $'\e[1;34mSelect an Authentication Method [1-3] (Enter to select the default "SQL"): \e[0m' auth_mode_selected
		auth_mode_selected=${auth_mode_selected:-1}
		if [ $auth_mode_selected == 1 ]; then
			authentication_mode="SQL"
		fi
		if [ $auth_mode_selected == 2 ]; then
			authentication_mode="AD"
		fi
		if [ $auth_mode_selected == 3 ]; then
			authentication_mode="NONE"
		fi
	done 
fi

#if scenario has not been passed and we are running with system that has no systemd
if [[ -z "$scenario" ]] && [[ "$is_instance_inside_container_active" == "YES" ]]; then
	echo -e "\x1B[2;34m============================================ Select Run Scenario ===========================================\x1B[0m" 
	echo "Run Scenario's:"
	echo ""
	echo "Defines the level of data collection from SQL instance"
	echo ""
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "|No |Run Scenario              |Description                                                                |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 1 |static_collect_kube.scn   |Passive data collection approach,focusing solely on copying standard logs  |"
	echo    "|   |                          |from the SQL without collecting any performance data.                      |"
	echo -e "|   |                          |\x1B[34m(Default) \x1B[0m                                                                 |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 2 |sql_perf_minimal_kube.scn |Collects minimal performance data from SQL without extended events         |"
	echo    "|   |                          |suitable for extended use.                                                 |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 3 |sql_perf_light_kube.scn   |Collects lightweight performance data from SQL, suitable for extended use. |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 4 |sql_perf_general_kube.scn |Collects general performance data from SQL, suitable for 15 to 20-minute   |"
	echo    "|   |                          |collection periods, covering most scenarios.                               |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo    "| 5 |sql_perf_detailed_kube.scn|Collects detailed performance data from SQL; avoid using this method for   |"
	echo    "|   |                          |extended periods as it generates a large amount of data.                   |"
	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
	echo ""
	scn_user_selected=""
	while [[ ${scn_user_selected} != [1-5] ]]
	do
		read -r -p $'\e[1;34mSelect a Scenario [1-5] (Enter to select the default "static_collect_kube.scn"): \e[0m' scn_user_selected
		scn_user_selected=${scn_user_selected:-1}
		if [[ ${scn_user_selected} == 1 ]]; then
			scenario="static_collect_kube.scn"
		fi
		if [[ ${scn_user_selected} == 2 ]]; then
			scenario="sql_perf_minimal_kube.scn"
		fi
		if [[ ${scn_user_selected} == 3 ]]; then
			scenario="sql_perf_light_kube.scn"
		fi
		if [[ ${scn_user_selected} == 4 ]]; then
			scenario="sql_perf_general_kube.scn"
		fi
		if [[ ${scn_user_selected} == 5 ]]; then
			scenario="sql_perf_detailed_kube.scn"
		fi
		echo ""
		CONFIG_FILE="./${scenario}"
		#echo "Reading configuration values from config scenario file $CONFIG_FILE" 
		echo "Reading configuration values from config scenario file $CONFIG_FILE" 
		if [[ -f $CONFIG_FILE ]]; then
			. $CONFIG_FILE
			cp -f ./${scenario} ./pssdiag_collector.conf
		else
 			echo "" 
	 		echo "Error reading configuration file specified as input, make sure that $scenario exists" 
			exit 1
		fi
	done 
fi

# #if authentication_mode has not been passed and we are running with system that has no systemd
# if [[ -z "$authentication_mode" ]] && [[ "$is_instance_inside_container_active" == "YES" ]]; then
# 	echo -e "\x1B[2;34m======================================== Select Authentication Mode ========================================\x1B[0m" 
# 	echo "Authentication Modes:"
# 	echo ""
# 	echo "Defines the Authentication Mode to use when connecting to SQL instance"
# 	echo ""
# 	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
# 	echo    "|No |Authentication Mode    |Description                                                                   |"
# 	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
# 	echo -e "| 1 |SQL                    |Use SQL Athentication. \x1B[34m(Default)\x1B[0m                                              |"
# 	echo    "+---+-----------------------+------------------------------------------------------------------------------+"
# 	echo ""
# 	auth_mode_selected=""
# 	while [[ ${auth_mode_selected} != [1] ]]
# 	do
# 		read -r -p $'\e[1;34mSelect an Authentication Method [1] (Enter to select the default "SQL"): \e[0m' auth_mode_selected
# 		auth_mode_selected=${auth_mode_selected:-1}
# 		if [ $auth_mode_selected == 1 ]; then
# 			authentication_mode="SQL"
# 		fi
# 	done 
# fi

# Specify all the defaults here if not specified in config file.
####################################################
COLLECT_OS_CONFIG=${COLLECT_CONFIG:-"NO"}
COLLECT_OS_LOGS=${COLLECT_OS_LOGS:-"NO"}
COLLECT_OS_COUNTERS=${COLLECT_OS_COUNTERS:-"NO"}
OS_COUNTERS_INTERVAL=${OS_COUNTERS_INTERVAL:=-"15"}
COLLECT_PERFSTATS=${COLLECT_PERFSTATS:-"NO"}
COLLECT_EXTENDED_EVENTS=${COLLECT_EXTENDED_EVENTS:-"NO"}
EXTENDED_EVENT_TEMPLATE=${EXTENDED_EVENT_TEMPLATE:-"pssdiag_xevent_light"}
COLLECT_SQL_TRACE=${COLLECT_SQL_TRACE:-"NO"}
SQL_TRACE_TEMPLATE=${SQL_TRACE_TEMPLATE:-"pssdiag_trace_light"}
COLLECT_SQL_COUNTERS=${COLLECT_SQL_COUNTERS:-"NO"}
SQL_COUNTERS_INTERVAL=${SQL_COUNTERS_INTERVAL:-"15"}
COLLECT_SQL_MEM_STATS=${COLLECT_SQL_MEM_STATS:-"NO"}
COLLECT_SQL_LOGS=${COLLECT_SQL_LOGS:-"NO"}
COLLECT_SQL_SEC_AD_LOGS=${COLLECT_SQL_SEC_AD_LOGS:-"NO"}
CUSTOM_COLLECTOR=${CUSTOM_COLLECTOR:-"NO"}
COLLECT_HOST_SQL_INSTANCE=${COLLECT_HOST_SQL_INSTANCE:-"NO"}
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"NO"}
if [[ ${authentication_mode} == "SQL" ]] || [[ ${authentication_mode} == "AD" ]] || [[ ${authentication_mode} == "NONE" ]]; then
	SQL_CONNECT_AUTH_MODE=${authentication_mode:-"SQL"}
fi
##############################################################

if [[ "$COLLECT_HOST_SQL_INSTANCE" == "NO" && "$COLLECT_CONTAINER" == "NO" ]] ; then
        COLLECT_SQL="NO"
else
        COLLECT_SQL="YES"
fi

	echo -e "\x1B[2;34m========================================== Checking Prerequisites ==========================================\x1B[0m" 

# check if we have all pre-requisite to perform data collection
./check_pre_req.sh $COLLECT_SQL $COLLECT_OS_COUNTERS $scenario $authentication_mode
if [[ $? -ne 0 ]] ; then
echo "Prerequisites for collecting all data are not met... exiting" 
exit 1
fi

if [[ -d "$outputdir" ]]; then
	read -n1 -r -p "Output directory {$outputdir}  exists.. Do you want to overwrite (Y/N) ?" diroverwrite
	echo "" 
	if [[ $diroverwrite = [Yy] ]] ;
	then
		rm -rf $outputdir
	else
		echo "Please delete the output directory and rerun the collector.." 
		exit 1
	fi
fi

# setup the output directory to collect data and logs
working_dir="$PWD"
outputdir="$working_dir/output"
pssdiag_log="$outputdir/pssdiag.log"

# Make sure output directory in working directory exists
mkdir -p $working_dir/output
chmod a+w $working_dir/output
cp pssdiag*.conf $working_dir/output
echo -e "\x1B[2;34m============================================================================================================\x1B[0m" >> $pssdiag_log
echo -e "$(date -u +"%T %D") Executing PSSDiag on ${HOSTNAME}"  >> $pssdiag_log
echo -e "$(date -u +"%T %D") Scenario file used ${scenario}" >> $pssdiag_log
echo -e "$(date -u +"%T %D") Authentication mode used ${authentication_mode}" >> $pssdiag_log
echo -e "$(date -u +"%T %D") Working Directory: ${working_dir}" >> $pssdiag_log 
echo -e "$(date -u +"%T %D") Output Directory: ${outputdir}" >> $pssdiag_log 
#get_host_instance_status
echo "$(date -u +"%T %D") is there any host instance service installed? ${is_host_instance_service_installed}" >> $pssdiag_log
echo "$(date -u +"%T %D") is host instance service enabled? ${is_host_instance_service_enabled}" >> $pssdiag_log
echo "$(date -u +"%T %D") is host instance service active? ${is_host_instnace_service_active}" >> $pssdiag_log
#get_container_instance_status
echo "$(date -u +"%T %D") is Docker installed? ${is_container_runtime_service_installed}" >> $pssdiag_log
echo "$(date -u +"%T %D") is Docker service enabled? ${is_container_runtime_service_enabled}" >> $pssdiag_log
echo "$(date -u +"%T %D") is Docker service active? ${is_container_runtime_service_active}" >> $pssdiag_log
echo "$(date -u +"%T %D") is using podamn without docker engine? ${is_podman_sql_containers}" >> $pssdiag_log
#pssdiag_inside_container_get_instance_status
echo "$(date -u +"%T %D") Are we running inside container? ${is_instance_inside_container_active}" >> $pssdiag_log
echo "$(date -u +"%T %D") PSSDiag version? ${script_version}" >> $pssdiag_log
echo "$(date -u +"%T %D") BASH_VERSION? ${BASH_VERSION}" >> $pssdiag_log
echo -e "\x1B[2;34m============================================= Starting PSSDiag =============================================\x1B[0m" | tee -a $pssdiag_log


# if we just need a snapshot of logs, we do not need to invoke background collectors
# so we short circuit to stop_collector and just collect static logs
if [[ "$scenario" == "static_collect.scn" ]] || [[ "$scenario" == "static_collect_kube.scn" ]];then
	echo -e "$(date -u +"%T %D") Static scenario was selected; performance data collection is not required... " | tee -a $pssdiag_log
	echo -e "$(date -u +"%T %D") Proceeding to stop and execute static log collection..." | tee -a $pssdiag_log
	./stop_collector.sh $authentication_mode
	exit 0
fi 


if [[ $COLLECT_OS_COUNTERS == [Yy][eE][sS] ]] ; then
        #Collecting Linux Perf countners
	echo -e "$(date -u +"%T %D") Starting operating system collectors..."  | tee -a $pssdiag_log
        echo -e "$(date -u +"%T %D") Starting io stats collector as a background job..." | tee -a $pssdiag_log
        (
        bash ./collect_io_stats.sh $OS_COUNTERS_INTERVAL &
        )
        echo -e "$(date -u +"%T %D") Starting cpu stats collector as a background job..." | tee -a $pssdiag_log
        (
        bash ./collect_cpu_stats.sh $OS_COUNTERS_INTERVAL &
        )
        echo -e "$(date -u +"%T %D") Starting memory collector as a background job..." | tee -a $pssdiag_log
        (
        bash ./collect_mem_stats.sh $OS_COUNTERS_INTERVAL &
        )
        echo -e "$(date -u +"%T %D") Starting process collector as a background job..." | tee -a $pssdiag_log
        (
        bash  ./collect_process_stats.sh $OS_COUNTERS_INTERVAL & 
        )
        echo -e "$(date -u +"%T %D") Starting network stats collector as a background job..." | tee -a $pssdiag_log
        (
        bash  ./collect_network_stats.sh $OS_COUNTERS_INTERVAL &
        )
        #Collecting Timezone required to process some of the data
        date +%z > $outputdir/${HOSTNAME}_os_timezone.info &
fi

#this section will connect to sql server instances and collect sql script outputs
#host instance
if [[ "$COLLECT_HOST_SQL_INSTANCE" == "YES" ]];then
	#we collect information from base host instance of SQL Server
	get_host_instance_status
	if [ "${is_host_instnace_service_active}" == "YES" ]; then
		SQL_LISTEN_PORT=$(get_sql_listen_port "host_instance")
		#SQL_SERVER_NAME="$HOSTNAME,$SQL_LISTEN_PORT"
		echo -e "" | tee -a $pssdiag_log
		echo -e "\x1B[7mCollecting startup information from host instance $HOSTNAME and port ${SQL_LISTEN_PORT}...\x1B[0m" | tee -a $pssdiag_log
		sql_connect "host_instance" "${HOSTNAME}" "${SQL_LISTEN_PORT}" "${authentication_mode}"
		sqlconnect=$?
		if [[ $sqlconnect -ne 1 ]]; then
			echo -e "\x1B[31mTesting the connection to host instance using $authentication_mode authentication failed." | tee -a $pssdiag_log
			echo -e "Please refer to the above lines for errors...\x1B[0m" | tee -a $pssdiag_log
		else
			sql_collect_perfstats "${HOSTNAME}" "host_instance"
			sql_collect_counters "${HOSTNAME}" "host_instance"
			sql_collect_memstats "${HOSTNAME}" "host_instance"
			sql_collect_custom "${HOSTNAME}" "host_instance"
			sql_collect_xevent "${HOSTNAME}" "host_instance"
			sql_collect_trace "${HOSTNAME}" "host_instance"
			sql_collect_config "${HOSTNAME}" "host_instance"
			sql_collect_linux_snapshot "${HOSTNAME}" "host_instance"
			sql_collect_perfstats_snapshot "${HOSTNAME}" "host_instance"


		fi
	fi
fi

#this section will connect to sql server instances and collect sql script outputs
#Collect informaiton if we are running inside container
if [[ "$COLLECT_HOST_SQL_INSTANCE" == "YES" ]];then
	pssdiag_inside_container_get_instance_status
	if [ "${is_instance_inside_container_active}" == "YES" ]; then
	    SQL_SERVER_NAME="$HOSTNAME,1433"
		echo -e "" | tee -a $pssdiag_log
		echo -e "\x1B[7mCollecting startup information from instance $HOSTNAME and port 1433...\x1B[0m" | tee -a $pssdiag_log
		sql_connect "instance" "${HOSTNAME}" "1433" "${authentication_mode}"
		sqlconnect=$?
		if [[ $sqlconnect -ne 1 ]]; then
			echo -e "\x1B[31mTesting the connection to instance using $authentication_mode authentication failed." | tee -a $pssdiag_log
			echo -e "Please refer to the above lines for errors...\x1B[0m" | tee -a $pssdiag_log
		else
			sql_collect_perfstats "${HOSTNAME}" "instance"
			sql_collect_counters "${HOSTNAME}" "instance"
			sql_collect_memstats "${HOSTNAME}" "instance"
			sql_collect_custom "${HOSTNAME}" "instance"
			sql_collect_xevent "${HOSTNAME}" "instance"
			sql_collect_trace "${HOSTNAME}" "instance"
			sql_collect_config "${HOSTNAME}" "instance"
			sql_collect_linux_snapshot "${HOSTNAME}" "instance"
			sql_collect_perfstats_snapshot "${HOSTNAME}" "instance"
		fi
	fi

fi

if [[ "$COLLECT_CONTAINER" != "NO" ]]; then
# we need to collect logs from containers
	get_container_instance_status
	if [ "${is_container_runtime_service_active}" == "YES" ]; then
        if [[ "$COLLECT_CONTAINER" != "ALL" ]]; then
        # we need to process just the specific container
            dockerid=$(docker ps -q --filter name=$COLLECT_CONTAINER)
            get_docker_mapped_port "${dockerid}"
 	        #SQL_SERVER_NAME="$dockername,$dockerport"
			echo -e "" | tee -a $pssdiag_log
			echo -e "\x1B[7mCollecting startup information from container instance ${dockername} and port ${dockerport}\x1B[0m" | tee -a $pssdiag_log
	        sql_connect "container_instance" "${dockername}" "${dockerport}" "${authentication_mode}"
        	sqlconnect=$?
	        if [[ $sqlconnect -ne 1 ]]; then
        	        echo -e "\x1B[31mTesting the connection to container instance using $authentication_mode authentication failed." | tee -a $pssdiag_log
					echo -e "Please refer to the above lines for errors...\x1B[0m" | tee -a $pssdiag_log
	        else
           	    sql_collect_perfstats "${dockername}" "container_instance"      
				sql_collect_counters "${dockername}" "container_instance"
	            sql_collect_memstats "${dockername}" "container_instance"
        	    sql_collect_custom "${dockername}" "container_instance"
                sql_collect_xevent "${dockername}" "container_instance"
				sql_collect_trace "${dockername}" "container_instance"
				sql_collect_config "${dockername}" "container_instance"
				sql_collect_linux_snapshot "${dockername}" "container_instance"
				sql_collect_perfstats_snapshot "${dockername}" "container_instance"
	        fi
	# we finished processing the requested container
        else
        # we need to iterate through all containers
			    #dockerid_col=$(docker ps | grep 'mcr.microsoft.com/mssql/server' | awk '{ print $1 }')
				dockerid_col=$(docker ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }')
                for dockerid in $dockerid_col;
                do
                	get_docker_mapped_port "${dockerid}"
	                #SQL_SERVER_NAME="$dockername,$dockerport"
					echo -e ""  | tee -a $pssdiag_log
					echo -e "\x1B[7mCollecting startup information from container_instance ${dockername} and port ${dockerport}\x1B[0m" | tee -a $pssdiag_log
	                sql_connect "container_instance" "${dockername}" "${dockerport}" "${authentication_mode}"
        	        sqlconnect=$?
                	if [[ $sqlconnect -ne 1 ]]; then
                        	echo -e "\x1B[31mTesting the connection to container instance using $authentication_mode authentication failed." | tee -a $pssdiag_log
							echo -e "Please refer to the above lines for connectivity and authentication errors...\x1B[0m" | tee -a $pssdiag_log
	                else
						sql_collect_perfstats "${dockername}" "container_instance"
                	    sql_collect_counters "${dockername}" "container_instance"
	                    sql_collect_memstats "${dockername}" "container_instance"
        	            sql_collect_custom "${dockername}" "container_instance"
                	    sql_collect_xevent "${dockername}" "container_instance"
						sql_collect_trace "${dockername}" "container_instance"
						sql_collect_config "${dockername}" "container_instance"
        	            sql_collect_linux_snapshot "${dockername}" "container_instance"
						sql_collect_perfstats_snapshot "${dockername}" "container_instance"
	                fi
                done;
			# we finished processing all the container
        fi
	fi
fi

# anchor
# at the end we will always launch an anchor script that we will use to detect if pssdiag is currently running
# if this anchor script is running already we will not allow another pssdiag run to proceed
bash ./pssdiag_anchor.sh &
anchorpid=$!
printf "%s\n" "$anchorpid" >> $outputdir/pssdiag_stoppids_os_collectors.txt
pgrep -P $anchorpid  >> $outputdir/pssdiag_stoppids_os_collectors.txt
# anchor

echo -e "\x1B[2;34m==============================  Startup Completd, Data Collection in Progress ==============================\x1B[0m" | tee -a $pssdiag_log
echo -e "" | tee -a $pssdiag_log
echo -e "\033[0;33m############################################################################################################\033[0;31m" | tee -a $pssdiag_log
echo -e "\033[0;33m#                 Please reproduce the problem now and then stop data collection afterwards                #\033[0;31m" | tee -a $pssdiag_log
echo -e "\033[0;33m############################################################################################################\033[0;31m" | tee -a $pssdiag_log
echo -e "" | tee -a $pssdiag_log
if [ "${is_instance_inside_container_active}" == "NO" ]; then
	echo -e "\033[1;33m    Performance collectors have started in the background. to stop them run 'sudo ./stop_collector.sh'...   \033[0m" | tee -a $pssdiag_log
else
	echo -e "\033[1;33m    Performance collectors have started in the background. to stop them run './stop_collector.sh'...   \033[0m" | tee -a $pssdiag_log
fi
echo -e "" | tee -a $pssdiag_log
exit 0
