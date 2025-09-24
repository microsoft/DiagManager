#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

# defining all functions upfront

sql_collect_perfstats()
{
        if [[ $COLLECT_PERFSTATS == [Yy][eE][sS] ]] ; then
			#Start regular PerfStats script as a background job
			logger "Starting SQL Perf Stats script as a background job" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}"
			`"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"$PerfStatsfilename" -o"$outputdir/${1}_${2}_SQL_Perf_Stats.out"` &
			mypid=$!
			#printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.log
			sleep 5s
			pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.log
        fi
}

sql_collect_perfstats_snapshot()
{    
		if [[ $COLLECT_PERFSTATS_SNAPSHOT == [Yy][eE][sS] ]] ; then
			logger "Collecting SQL Perf Stats Snapshot at Startup" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_perf_stats_snapshot.sql" -o"$outputdir/${1}_${2}_SQL_Perf_Stats_Snapshot_Startup.out"
		fi
}

sql_collect_highcpu_stats()
{
		if [[ $COLLECT_HIGHCPU_PERFSTATS == [Yy][eE][sS] ]] ; then
			#Start HighCPU Stats script as a background job
			logger "Starting SQL High CPU Stats script as a background job" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			`"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_highcpu_perf_stats.sql" -o"$outputdir/${1}_${2}_SQL_HighCPU_Perf_Stats.out"` &
			mypid=$!
			#printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.log
			sleep 5s
			pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.log
		fi
}

sql_collect_highio_stats()
{
		if [[ $COLLECT_HIGHIO_PERFSTATS == [Yy][eE][sS] ]] ; then
			#Start High_IO Stats script as a background job
			logger "Starting SQL High IO Stats script as a background job" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			`"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_highio_perf_stats.sql" -o"$outputdir/${1}_${2}_SQL_HighIO_Perf_Stats.out"` &
			mypid=$!
			#printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.log
			sleep 5s
			pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.log
		fi
}

sql_collect_linux_perf_stats()
{
		if [[ $COLLECT_LINUX_PERFSTATS == [Yy][eE][sS] ]] ; then
			#Start Linux Stats script as a background job
			logger "Starting SQL Linux Stats script as a background job" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			`"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_linux_perf_stats.sql" -o"$outputdir/${1}_${2}_SQL_Linux_Perf_Stats.out"` &
			mypid=$!
			#printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.log
			sleep 5s
			pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.log
		fi
}

sql_collect_linux_snapshot()
{
        if [[ $COLLECT_PERFSTATS_SNAPSHOT == [Yy][eE][sS] ]] ; then
			logger "Collecting SQL Linux Snapshot at Startup" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        	"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_linux_perf_stats_snapshot.sql" -o"$outputdir/${1}_${2}_SQL_Linux_Perf_Stats_Snapshot_Startup.out"
		fi
}

sql_collect_memstats()
{
        if [[ $COLLECT_SQL_MEM_STATS == [Yy][eE][sS] ]] ; then
			#Start SQL Memory Status script as a background job
			logger "Starting SQL Memory Status script as a background job" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			`"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_mem_stats.sql" -o"$outputdir/${1}_${2}_SQL_Mem_Stats.out"` &
			mypid=$!
			#printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.log
			sleep 5s
			pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.log
        fi
}

sql_collect_counters()
{
        if [[ $COLLECT_SQL_COUNTERS == [Yy][eE][sS] ]] ; then
			#Start sql performance counter script as a background job
			#Replace Interval with SED
			sed -i'' -e"2s/.*/SET @SQL_COUNTER_INTERVAL = $SQL_COUNTERS_INTERVAL/g" sql_performance_counters.sql
			logger "Starting SQL Performance counter script as a background job" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			`"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_performance_counters.sql" -o"$outputdir/${1}_${2}_SQL_Performance_Counters.out"` &
			mypid=$!
			#printf "%s\n" "$mypid" >> $outputdir/pssdiag_stoppids_sql_collectors.log
			sleep 5s
			pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.log
        fi
}

sql_collect_sql_custom()
{
        if [[ $CUSTOM_COLLECTOR == [Yy][eE][sS] ]] ; then
			#Start Custom Collector  scripts as a background job
			logger "Starting SQL Custom Collector Scripts as a background job" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			for filename in my_sql_custom_collector*.sql; do
				`"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"${filename}" -o"$outputdir/${1}_${2}_${filename}_Output.out"` &
				mypid=$!
				sleep 5s
				pgrep -P $mypid  >> $outputdir/pssdiag_stoppids_sql_collectors.log
			done
        fi
}

sql_collect_xevent()
{
        #start any XE collection if defined? XE file should be named pssdiag_xevent_.sql.
        if [[ $COLLECT_EXTENDED_EVENTS == [Yy][eE][sS]  ]]; then
			logger "Starting SQL Extended Events collection" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}"
			"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"${EXTENDED_EVENT_TEMPLATE}.sql" -o"$outputdir/${1}_${2}_pssdiag_xevent.log"  
			cp -f ./pssdiag_xevent_start.template ./pssdiag_xevent_start.sql
		if [[ "$2" == "host_instance" ]] || [[ "$2" == "instance" ]]; then
			sed -i "s|##XeFileName##|${outputdir}/${1}_${2}_pssdiag_xevent.xel|" pssdiag_xevent_start.sql
		else
			sed -i "s|##XeFileName##|/tmp/${1}_${2}_pssdiag_xevent.xel|" pssdiag_xevent_start.sql
		fi
			"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"pssdiag_xevent_start.sql" -o"$outputdir/${1}_${2}_pssdiag_xevent_start.log"
        fi
}

sql_collect_trace()
{
        #start any SQL trace collection if defined? 
        if [[ $COLLECT_SQL_TRACE == [Yy][eE][sS]  ]]; then
			logger "Starting SQL Trace collection" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}"
			"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"msdiagprocs.sql" -o"$outputdir/${1}_${2}_MSDiagprocs.out"  
			echo -e "$(date -u +"%T %D") Starting SQL trace collection...  " | tee -a $pssdiag_log
			cp -f ./${SQL_TRACE_TEMPLATE}.template ./pssdiag_trace_start.sql
		if [[ "$2" == "host_instance" ]] || [[ "$2" == "instance" ]]; then
			sed -i "s|##TraceFileName##|${outputdir}/${1}_${2}_pssdiag_trace|" pssdiag_trace_start.sql
		else
			sed -i "s|##TraceFileName##|/tmp/${1}_${2}_pssdiag_trace|" pssdiag_trace_start.sql
		fi
			"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"pssdiag_trace_start.sql" -o"$outputdir/${1}_${2}_pssdiag_trace_start.out"
        fi
}

sql_collect_config()
{
        if [[ $COLLECT_SQL_CONFIG == [Yy][eE][sS] ]] ; then
			#include whatever base collector scripts exist here
			logger "Collecting SQL Configuration information at startup" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        	"$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_configuration.sql" -o"$outputdir/${1}_${2}_SQL_Configuration_Startup.out"
		fi
}

# end of all function definitions

#########################
# Start of main script  #
# - start_collector.sh  #
#########################

get_host_instance_status
get_container_instance_status
pssdiag_inside_container_get_instance_status
get_wsl_instance_status
find_sqlcmd

#Checks: if user passed any parameter to the script 
scenario=${1,,}
authentication_mode=${2^^}
PerfStatsfilename="${3,,}"; : "${PerfStatsfilename:=sql_perf_stats.sql}"

# setup the output directory to collect data and logs
working_dir="$PWD"
outputdir="$working_dir/output"

#Checks: if output directory exists, if yes prompt to overwrite
if [[ -d "$outputdir" ]]; then
  echo -e "\e[31mOutput directory {$outputdir} exists..\e[0m"
  read -p "Do you want to overwrite? (y/n): " choice < /dev/tty 2> /dev/tty
  case "$choice" in
    y|Y ) ;;
    n|N ) exit 1;;
    * ) exit 1;;
  esac
fi

# Checks: Make sure the output directory is not owned by root, this is the case when the collection was started sudo earlier, and now without sudo.
if [ "$(id -u)" -ne 0 ]; then
    if [ -e "$outputdir" ]; then
        owner=$(stat -c '%U' "$outputdir")  # Use -f '%Su' on macOS
        if [ "$owner" = "root" ]; then
            echo "The folder \"$outputdir\" is owned by root."
			echo "This folder cannot be deleted because PSSDiag was started without elevated (sudo) permissions. Please remove it manually using sudo, then re-run the script."
            exit 1
        fi
    fi
fi

# --remove the output directory
if [ -d "$outputdir" ]; then
  rm -rf "$outputdir"
fi
mkdir -p $working_dir/output
chmod a+w $working_dir/output
if [ "$EUID" -eq 0 ]; then
  group=$(id -gn "$SUDO_USER")
  chown "$SUDO_USER:$group" "$outputdir" -R
else
	chown $(id -u):$(id -g) "$outputdir" -R
fi

#setting up the log file, and set the directive to send errors presented to user to the log file.
pssdiag_log="$outputdir/pssdiag.log"
exec 2> >(tee -a $pssdiag_log >&2) 


# Checks: if we run without SUDO and not inside a container, provide the warning of what would happen if we run without elevated permissions
if [ -z "$SUDO_USER" ] && [ "$is_instance_inside_container_active" = "NO" ]; then
	echo -e ""
	echo -e "\e[31mWarning: PSSDiag was started without elevated (sudo) permissions.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[31mElevated (sudo) permissions are required for PSSDiag to collect complete diagnostic dataset.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "" | tee -a "$pssdiag_log"
	echo -e "\e[31mWithout elevated permissions:\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[31m** PSSDiag will not able to read mssql.conf to get SQL log file location and port number.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[31m** PSSDiag will not able to copy errorlog, extended events and dump files..\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[31m** Some host OS log collector may fail.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[31m** All SQL container collectors will fail.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[31m** Only T-SQL based collectors will be able run for SQL host instance with default port 1433.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "" | tee -a "$pssdiag_log"
	echo -e "\e[33mIf you still prefer to run PSSDiag without elevated (sudo) permissions, please ensure the user executing PSSDiag has the following:.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[33m** Ownership of PSSDiag folder.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[33m** Read access to mssql.conf, as well as the SQL log and dump directories.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[33m** Membership in the Docker group (or an equivalent group), if data is being collected from containers.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "" | tee -a "$pssdiag_log"
	read -p "Do you want to continue? (y/n): " choice < /dev/tty 2> /dev/tty
	case "$choice" in
		y|Y ) ;;
		n|N ) exit 1;;
		* ) exit 1;;
	esac
fi

#Checks: make sure we have a valid authentication entered, we are not running inside container.
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

#Checks: make sure we have a valid authentication entered, we are running with inside container
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

# ─────────────────────────────────────────────────────────────────────────────────────
# - Get user input for PerfStatsfilename                  
# - Check if PerfStatsfilename is valid, set to default if not
# - PSSDiag...               
# ─────────────────────────────────────────────────────────────────────────────────────
PerfStatsfilename_allowed_values=("sql_perf_stats_lite.sql" "sql_perf_stats.sql")
if [[ ! " ${PerfStatsfilename_allowed_values[@]} " =~ " ${PerfStatsfilename} " ]]; then
    PerfStatsfilename="sql_perf_stats.sql"
fi

# ─────────────────────────────────────────────────────────────────────────────────────
# - Get user input for scenario   
# - if scenario has not been passed and we are running with systemd system                  
# - PSSDiag running on host OS                
# ─────────────────────────────────────────────────────────────────────────────────────

if [[ -z "$scenario" ]] && [[ "$is_instance_inside_container_active" == "NO" ]]; then
	echo -e "Run Scenario:"
	echo ""
	echo "Specify the level of data collection from Host OS and SQL instance, whether the SQL instance is running on the host or within a container"
	echo ""
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo -e "|No |Scenario file                      |Description                                                                   |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 1 |scenario_static.scn                |Passive data collection approach,focusing solely on copying standard logs from|"
	echo -e "|   |                                   |host OS and SQL without collecting any performance data. \033[;94m(Default)\x1B[0m            |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 2 |scenario_sql_perf_minimal.scn      |Collects minimal performance data from SQL without extended events            |"
	echo    "|   |                                   |suitable for extended use.                                                    |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 3 |scenario_sql_perf_lite.scn         |Collects lightweight performance data from SQL and host OS,                   |"
	echo    "|   |                                   |suitable for extended use.                                                    |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 4 |scenario_sql_perf_general.scn      |Collects general performance data from SQL and host OS, ideal for             |"
	echo    "|   |                                   |15 to 20-minute collection periods, covering most scenarios.                  |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo -e "| 5 |scenario_sql_perf_detailed.scn     |Collects detailed performance data at statement level, \033[1;31mUse with Caution\033[0m       |"
	echo    "|   |                                   |may impact server performance due to overhead.                                |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo ""
	scn_user_selected=""
	while [[ ${scn_user_selected} != [1-5] ]]
	do
		read -r -p $'\e[1;34mSelect a Scenario [1-5] (Enter to select the default "scenario_static.scn"): \e[0m' scn_user_selected < /dev/tty 2> /dev/tty

		#Set the defaul scnario to 1 if user just hits enter
		scn_user_selected=${scn_user_selected:-1}

		#check if we have a valid selection
		if [[ ! "$scn_user_selected" =~ ^[1-5]$ ]]; then
    		echo "Invalid selection. Exiting..."
    		exit 1
		fi

		#Set the scenario variable based on user selection
		if [[ ${scn_user_selected} == 1 ]]; then
			scenario="scenario_static.scn"
		fi
		if [[ ${scn_user_selected} == 2 ]]; then
			scenario="scenario_sql_perf_minimal.scn"
		fi
		if [[ ${scn_user_selected} == 3 ]]; then
			scenario="scenario_sql_perf_lite.scn"
		fi
		if [[ ${scn_user_selected} == 4 ]]; then
			scenario="scenario_sql_perf_general.scn"
		fi
		if [[ ${scn_user_selected} == 5 ]]; then
			scenario="scenario_sql_perf_detailed.scn"
		fi
		echo ""

		#Check if scenario is set to one of the performance-impacting options
		if [[ "$scenario" == "scenario_sql_perf_detailed.scn" ]]; then
	    echo -e "\033[0;31mAre you sure you want to use scenario: $scenario?\033[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
    	echo -e "\033[0;31mThis will collect performance data at the statement level, which may impact server performance due to overhead..\033[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")

			read -p "Do you want to continue? (y/n): " choice

			case "$choice" in
				yes|y|Y)
					echo "Proceeding with scenario: $scenario"
					echo ""
					;;
				no|n|N)
					echo "Exiting as requested."
					exit 1
					;;
				*)
					echo "Invalid input. Exiting."
					exit 1
					;;
			esac
		fi
	done 
fi

# ─────────────────────────────────────────────────────────────────────────────────────
# - Get user input for authentication_mode   
# - if authentication_mode has not been passed                
# - PSSDiag running on host OS                
# ─────────────────────────────────────────────────────────────────────────────────────

#if authentication_mode has not been passed and we are running with systemd system, ask the user for input
if [[ -z "$authentication_mode" ]] && [[ "$is_instance_inside_container_active" == "NO" ]]; then
	echo -e "Authentication Mode:"
	echo ""
	echo "Defines the Authentication Mode to use when connecting to SQL whether they are host or container instance"
	echo ""
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "|No |Authentication Mode                |Description                                                                   |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo -e "| 1 |SQL                                |Use SQL Authentication. \033[;94m(Default)\x1B[0m                                             |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 2 |AD                                 |Use AD Authentication                                                         |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 3 |NONE                               |Allows to select the method per instance when multiple instances              |"
	echo    "|   |                                   |host instance and container instance/s running on the same host,              |"
	echo    "|   |                                   |not applicable for sql running on Kubernetes                                  |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo ""
	auth_mode_selected=""
	while [[ ${auth_mode_selected} != [1-3] ]]
	do
		read -r -p $'\e[1;34mSelect an Authentication Method [1-3] (Enter to select the default "SQL"): \e[0m' auth_mode_selected < /dev/tty 2> /dev/tty

		#set the default authentication mode to 1 if user just hits enter
		auth_mode_selected=${auth_mode_selected:-1}

		#check if we have a valid selection
		if [[ ! "$auth_mode_selected" =~ ^[1-3]$ ]]; then
    		echo "Invalid selection. Exiting..."
    		exit 1
		fi

		#set the authentication_mode variable based on user selection
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

# ─────────────────────────────────────────────────────────────────────────────────────
# - Get user input for scenario                  
# - if scenario has not been passed and we are with no systemd     
# - PSSDiag running inside container               
# ─────────────────────────────────────────────────────────────────────────────────────
if [[ -z "$scenario" ]] && [[ "$is_instance_inside_container_active" == "YES" ]]; then
	echo "Run Scenario:"
	echo ""
	echo "Specify the level of data collection from SQL"
	echo ""
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "|No |Scenario file                      |Description                                                                   |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 1 |scenario_static_kube.scn           |Passive data collection approach,focusing solely on copying standard logs     |"
	echo -e "|   |                                   |from SQL without collecting any performance data. \033[;94m(Default)\x1B[0m                   |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 2 |scenario_sql_perf_minimal_kube.scn |Collects minimal performance data from SQL without extended events            |"
	echo    "|   |                                   |suitable for extended use.                                                    |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 3 |scenario_sql_perf_lite_kube.scn    |Collects lightweight performance data from SQL, suitable for extended use.    |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo    "| 4 |scenario_sql_perf_general_kube.scn |Collects general performance data from SQL, Ideal for 15 to 20-minute         |"
	echo    "|   |                                   |collection periods, covering most scenarios.                                  |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo -e "| 5 |scenario_sql_perf_detailed_kube.scn|Collects detailed performance data at statement level, \033[1;31mUse with Caution\033[0m       |"
	echo    "|   |                                   |may impact server performance due to overhead.                                |"
	echo    "+---+-----------------------------------+------------------------------------------------------------------------------+"
	echo ""
	scn_user_selected=""
	while [[ ${scn_user_selected} != [1-5] ]]
	do
		read -r -p $'\e[1;34mSelect a Scenario [1-5] (Enter to select the default "scenario_static_kube.scn"): \e[0m' scn_user_selected < /dev/tty 2> /dev/tty

		scn_user_selected=${scn_user_selected:-1}

		#check if we have a valid selection
		if [[ ! "$scn_user_selected" =~ ^[1-5]$ ]]; then
    		echo "Invalid selection. Exiting..."
    		exit 1
		fi

		if [[ ${scn_user_selected} == 1 ]]; then
			scenario="scenario_static_kube.scn"
		fi
		if [[ ${scn_user_selected} == 2 ]]; then
			scenario="scenario_sql_perf_minimal_kube.scn"
		fi
		if [[ ${scn_user_selected} == 3 ]]; then
			scenario="scenario_sql_perf_lite_kube.scn"
		fi
		if [[ ${scn_user_selected} == 4 ]]; then
			scenario="scenario_sql_perf_general_kube.scn"
		fi
		if [[ ${scn_user_selected} == 5 ]]; then
			scenario="scenario_sql_perf_detailed_kube.scn"
		fi
		echo ""

		#Check if scenario is set to one of the performance-impacting options
		if [[ "$scenario" == "scenario_sql_perf_detailed_kube.scn" ]]; then
	    echo -e "\033[0;31mAre you sure you want to use scenario: $scenario?\033[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
    	echo -e "\033[0;31mThis will collect performance data at the statement level, which may affect server performance due to overhead..\033[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")

			read -p "Do you want to continue? (y/n): " choice

			case "$choice" in
				yes|y|Y)
					echo "Proceeding with scenario: $scenario"
					echo ""
					;;
				no|n|N)
					echo "Exiting as requested."
					exit 1
					;;
				*)
					echo "Invalid input. Exiting."
					exit 1
					;;
			esac
		fi
	done 
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────────────
# - Validate  
# ─────────────────────────────────────────────────────────────────────────────────────

logger "Validating run scenario, environment and prerequisites" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}"

#Check if the variable is set
if [[ -n "$scenario" ]]; then
    CONFIG_FILE="./${scenario}"
    if [[ -f "$CONFIG_FILE" ]]; then
		logger "Validating scenario file $CONFIG_FILE" "info" "1" "1" "${pssdiag_log:-/dev/null}"  "${0##*/}" 
        validate_scenario_file "$CONFIG_FILE"
        valid=$?
        if [[ $valid == 0 ]]; then
            # If the file is valid, source the content and create pssdiag_collector.conf for PSSDiag.
        	logger "Scenario file $scenario is valid, Reading settings" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
            source "$CONFIG_FILE"
            cp -f "$CONFIG_FILE" ./pssdiag_collector.conf
        else
        	logger "Scenario file $scenario is not valid, check previous errors no how to rectify the file..." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        	logger "PSSDiag needs a valid Scenario file to continue, exiting" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
            exit 1
        fi
    else
		logger "Error reading configuration file specified as input, make sure that $scenario exists" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        exit 1
    fi
fi

# Specify all the defaults here if not specified in config file.
####################################################
COLLECT_HOST_OS_INFO=${COLLECT_HOST_OS_INFO:-"NO"}
SCENARIO_COLLECTION_TYPE=${SCENARIO_COLLECTION_TYPE:-"STATIC"}
COLLECT_OS_CONFIG=${COLLECT_CONFIG:-"NO"}
COLLECT_OS_LOGS=${COLLECT_OS_LOGS:-"NO"}
COLLECT_OS_COUNTERS=${COLLECT_OS_COUNTERS:-"NO"}
OS_COUNTERS_INTERVAL=${OS_COUNTERS_INTERVAL:=-"15"}
COLLECT_PERFSTATS=${COLLECT_PERFSTATS:-"NO"}
COLLECT_SQL_CONFIG=${COLLECT_SQL_CONFIG:-"NO"}
COLLECT_PERFSTATS_SNAPSHOT=${COLLECT_PERFSTATS_SNAPSHOT:-"NO"}
COLLECT_HIGHCPU_PERFSTATS=${COLLECT_HIGHCPU_PERFSTATS:-"NO"}
COLLECT_HIGHIO_PERFSTATS=${COLLECT_HIGHIO_PERFSTATS:-"NO"}
COLLECT_LINUX_PERFSTATS=${COLLECT_LINUX_PERFSTATS:-"NO"}
COLLECT_EXTENDED_EVENTS=${COLLECT_EXTENDED_EVENTS:-"NO"}
EXTENDED_EVENT_TEMPLATE=${EXTENDED_EVENT_TEMPLATE:-"pssdiag_xevent_lite"}
COLLECT_SQL_TRACE=${COLLECT_SQL_TRACE:-"NO"}
SQL_TRACE_TEMPLATE=${SQL_TRACE_TEMPLATE:-"pssdiag_trace_lite"}
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

#by default we collect containers logs, many times there are no conatiners, it would be better to skip the logic for collect from containers
#Here we are checking if we have SQL container running on the host, if not we set COLLECT_CONTAINER to NO regardless of what is set in the config file, scn file.
COLLECT_CONTAINER="${COLLECT_CONTAINER^^}"
if [[ "$COLLECT_CONTAINER" != "NO" && "$is_docker_sql_containers" == "NO" ]] ; then
	COLLECT_CONTAINER="NO"
	sed -i 's/^COLLECT_CONTAINER=.*/COLLECT_CONTAINER=NO/' ./pssdiag_collector.conf
fi

# Determine if we need to collect SQL data at all
if [[ "$COLLECT_HOST_SQL_INSTANCE" == "NO" && "$COLLECT_CONTAINER" == "NO" ]] ; then
        COLLECT_SQL="NO"
else
        COLLECT_SQL="YES"
fi

#get copy of current config, to output directory, it will be part of log collection.
cp pssdiag*.conf $working_dir/output

#get the user that started pssdiag and save it to log file in the current directory NOT the output directory
if [ "$EUID" -eq 0 ]; then
    echo "SUDO:YES" > "$outputdir/pssdiag_intiated_as_user.log"
	chown $(id -u "$SUDO_USER"):$(id -g "$SUDO_USER") "$outputdir/pssdiag_intiated_as_user.log"
	echo "SUDO_USER:$SUDO_USER" >> "$outputdir/pssdiag_intiated_as_user.log"
else
    echo "SUDO:NO" > "$outputdir/pssdiag_intiated_as_user.log"
	chown $(id -u):$(id -g) "$outputdir/pssdiag_intiated_as_user.log"
	echo "USER:$(id -un)" >> "$outputdir/pssdiag_intiated_as_user.log"
	echo "GROUP:$(id -gn)" >> "$outputdir/pssdiag_intiated_as_user.log"
fi

#Logging all the settings we are using for this run, or detected.
logger "Detecting environment and execution context" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "PSSDiag Executed with sudo: $([ -n "$SUDO_USER" ] && echo "YES" || echo "NO")" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "PSSDiag version: ${script_version}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Executing PSSDiag on: ${HOSTNAME}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Scenario file selected: ${scenario}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Perf Stats file selected: ${PerfStatsfilename}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Authentication mode selected: ${authentication_mode}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Working Directory: ${working_dir}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Output Directory: ${outputdir}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
#get_host_instance_status
logger "Host instance service installed? ${is_host_instance_service_installed}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Host instance service enabled? ${is_host_instance_service_enabled}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Host instance service active? ${is_host_instance_service_active}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Host instance process running? ${is_host_instance_process_running}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
#get_container_instance_status
logger "Docker installed? ${is_container_runtime_service_installed}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Docker service enabled? ${is_container_runtime_service_enabled}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Docker service active? ${is_container_runtime_service_active}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Using sql docker containers? ${is_docker_sql_containers}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Using sql podman containers? ${is_podman_sql_containers}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Using sql podman containers without docker engine? ${is_podman_sql_containers_no_docker_runtime}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
#pssdiag_inside_container_get_instance_status
logger "Running inside container? ${is_instance_inside_container_active}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "Running inside WSL? ${is_host_instance_inside_wsl}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "WSL version? ${wsl_version}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
#Check OS build info
logger "Running on an Azure VM? $([ "$(cat /sys/devices/virtual/dmi/id/chassis_asset_tag 2>/dev/null)" = "7783-7084-3265-9085-8269-3286-77" ] && echo "YES" || echo "NO")" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "HOST Distribution: $(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"') $(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "HOST Kernel: $(uname -r)" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger "BASH_VERSION: ${BASH_VERSION}" "info" "0" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

# check if we have all pre-requisite to perform data collection
logger "Checking prerequisites" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
./check_pre_req.sh $COLLECT_SQL $COLLECT_OS_COUNTERS $scenario $authentication_mode
if [[ $? -ne 0 ]] ; then
	logger "Prerequisites for collecting all data are not met, exiting" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	exit 1
else
	logger "All prerequisites for collecting data are met, proceeding" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
fi

#Start of PSSDiag
logger "Initialization complete, starting collectors" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}"


# ─────────────────────────────────────────────────────────────────────────────────────
# - Starting collectors
# ─────────────────────────────────────────────────────────────────────────────────────

# if we just need a snapshot of logs, we do not need to invoke background collectors
# so we short circuit to stop_collector and just collect static logs
if [[ $SCENARIO_COLLECTION_TYPE == [Ss][Tt][Aa][Tt][Ic][Cc] ]] ; then
	logger "Static scenario was selected; performance data collection is not required" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	logger "Proceeding to next stage, execute static log collectors" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	./stop_collector.sh $authentication_mode
	exit 0
fi 

logger "Starting Perf collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

if [[ $COLLECT_HOST_OS_INFO == [Yy][eE][sS] && $COLLECT_OS_COUNTERS == [Yy][eE][sS] ]] ; then
        #Collecting Linux Perf countners
        logger "Starting operating system collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		
        logger "Starting io stats collector as a background job..." "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        (
        bash ./collect_io_stats.sh $OS_COUNTERS_INTERVAL &
        )
        logger "Starting cpu stats collector as a background job..." "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        (
        bash ./collect_cpu_stats.sh $OS_COUNTERS_INTERVAL &
        )
        logger "Starting memory collector as a background job..." "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        (
        bash ./collect_mem_stats.sh $OS_COUNTERS_INTERVAL &
        )
        logger "Starting process collector as a background job..." "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        (
        bash  ./collect_process_stats.sh $OS_COUNTERS_INTERVAL & 
        )
        logger "Starting network stats collector as a background job..." "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        (
        bash  ./collect_network_stats.sh $OS_COUNTERS_INTERVAL &
        )
        #Collecting Timezone required to process some of the data
        date +%z > $outputdir/${HOSTNAME}_os_timezone.info &
fi

######################################################################################
# TSQL based collectors                                                              #
# - this section will connect to sql server instances and collect sql script outputs #
######################################################################################

# ────────────────────────────
# - Collect "host_instance"                   
# - SQL running on VM                
# - PSSDiag is running on host       
# ────────────────────────────


if [[ "$COLLECT_HOST_SQL_INSTANCE" == [Yy][eE][sS] ]];then
	#we collect information from base host instance of SQL Server
	get_host_instance_status
	if [ "${is_host_instance_process_running}" == "YES" ]; then
		SQL_LISTEN_PORT=$(get_sql_listen_port "host_instance")
		logger "Collecting information from host instance $HOSTNAME and port ${SQL_LISTEN_PORT}" "info_highlight" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		sql_connect "host_instance" "${HOSTNAME}" "${SQL_LISTEN_PORT}" "${authentication_mode}"
		sqlconnect=$?
		if [[ $sqlconnect -ne 1 ]]; then
			logger "Connection to host instance using $authentication_mode authentication failed." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			logger "Please refer to the above lines for errors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			logger "Skipping perf TSQL based collectors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		else
			logger "Starting perf TSQL based collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			sql_collect_perfstats "${HOSTNAME}" "host_instance"
			sql_collect_highcpu_stats "${HOSTNAME}" "host_instance"
			sql_collect_highio_stats "${HOSTNAME}" "host_instance"
			sql_collect_counters "${HOSTNAME}" "host_instance"
			sql_collect_memstats "${HOSTNAME}" "host_instance"
			sql_collect_sql_custom "${HOSTNAME}" "host_instance"
			sql_collect_xevent "${HOSTNAME}" "host_instance"
			sql_collect_trace "${HOSTNAME}" "host_instance"
			sql_collect_config "${HOSTNAME}" "host_instance"
			sql_collect_linux_snapshot "${HOSTNAME}" "host_instance"
			sql_collect_perfstats_snapshot "${HOSTNAME}" "host_instance"
		fi
	fi
fi

# ──────────────────────────────────────
# - Collect "instance"                   
# - SQL running inside container
# - PSSDiag is running inside container       
# ──────────────────────────────────────

if [[ "$COLLECT_HOST_SQL_INSTANCE" == [Yy][eE][sS] ]];then
	pssdiag_inside_container_get_instance_status
	if [ "${is_instance_inside_container_active}" == "YES" ]; then
	    SQL_SERVER_NAME="$HOSTNAME,1433"
		logger "Collecting information from instance $HOSTNAME and port 1433" "info_highlight" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		sql_connect "instance" "${HOSTNAME}" "1433" "${authentication_mode}"
		sqlconnect=$?
		if [[ $sqlconnect -ne 1 ]]; then
			logger "Connection to instance using $authentication_mode authentication failed." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			logger "Please refer to the above lines for errors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			logger "Skipping perf TSQL based collectors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		else
			logger "Starting perf TSQL based collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			sql_collect_perfstats "${HOSTNAME}" "instance"
			sql_collect_highcpu_stats "${HOSTNAME}" "instance"
			sql_collect_highio_stats "${HOSTNAME}" "instance"
			sql_collect_counters "${HOSTNAME}" "instance"
			sql_collect_memstats "${HOSTNAME}" "instance"
			sql_collect_sql_custom "${HOSTNAME}" "instance"
			sql_collect_xevent "${HOSTNAME}" "instance"
			sql_collect_trace "${HOSTNAME}" "instance"
			sql_collect_config "${HOSTNAME}" "instance"
			sql_collect_linux_snapshot "${HOSTNAME}" "instance"
			sql_collect_perfstats_snapshot "${HOSTNAME}" "instance"
		fi
	fi
fi

# ──────────────────────────────────────
# - Collect "container_instance"                   
# - SQL running as docker container
# - PSSDiag is running on VM       
# ──────────────────────────────────────

if [[ "$COLLECT_CONTAINER" != [Nn][Oo] ]]; then
# we need to collect logs from containers
	get_container_instance_status
	if [ "${is_container_runtime_service_active}" == "YES" ]; then
        if [[ "$COLLECT_CONTAINER" != [Aa][Ll][Ll] ]]; then
        # we need to process just the specific container
            dockerid=$(docker ps -q --filter name=$COLLECT_CONTAINER)
            get_docker_mapped_port "${dockerid}"
			logger "Collecting information from container instance ${dockername} and port ${dockerport}" "info_highlight" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	        sql_connect "container_instance" "${dockername}" "${dockerport}" "${authentication_mode}"
        	sqlconnect=$?
	        if [[ $sqlconnect -ne 1 ]]; then
        	    logger "Connection to container instance using $authentication_mode authentication failed." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
				logger "Please refer to the above lines for errors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
				logger "Skipping perf TSQL based collectors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	        else
           	    logger "Starting perf TSQL based collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
				sql_collect_perfstats "${dockername}" "container_instance"      
				sql_collect_highcpu_stats "${dockername}" "container_instance" 
				sql_collect_highio_stats "${dockername}" "container_instance" 
				sql_collect_counters "${dockername}" "container_instance"
	            sql_collect_memstats "${dockername}" "container_instance"
        	    sql_collect_sql_custom "${dockername}" "container_instance"
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
					logger "Collecting information from container instance ${dockername} and port ${dockerport}" "info_highlight" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	                sql_connect "container_instance" "${dockername}" "${dockerport}" "${authentication_mode}"
        	        sqlconnect=$?
                	if [[ $sqlconnect -ne 1 ]]; then
                        	logger "Connection to container instance using $authentication_mode authentication failed." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
							logger "Please refer to the above lines for errors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
							logger "Skipping perf TSQL based collectors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	                else
						logger "Starting perf TSQL based collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
						sql_collect_perfstats "${dockername}" "container_instance"
						sql_collect_highcpu_stats "${dockername}" "container_instance"
						sql_collect_highio_stats "${dockername}" "container_instance"
                	    sql_collect_counters "${dockername}" "container_instance"
	                    sql_collect_memstats "${dockername}" "container_instance"
        	            sql_collect_sql_custom "${dockername}" "container_instance"
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
printf "%s\n" "$anchorpid" >> $outputdir/pssdiag_stoppids_os_collectors.log
pgrep -P $anchorpid  >> $outputdir/pssdiag_stoppids_os_collectors.log
# anchor

logger "Startup completed, data collection in progress" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
#empty line
logger " " "header_blue" "1" "1" "${pssdiag_log:-/dev/null}" "" " " "0"

#box the next mesg
logger "#" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}" "" "#" "0"
logger "Please reproduce the problem now and then stop data collection afterwards" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}" "" "#" "1"
logger "#" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}"  "" "#" "0"
#empty line
logger " " "header_blue" "1" "1" "${pssdiag_log:-/dev/null}"  "" " " "0"

if [ "${is_instance_inside_container_active}" == "NO" ]; then
	logger "Performance collectors have started in the background. to stop them run 'sudo ./stop_collector.sh'" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}" "" " " "0"
else
	logger "Performance collectors have started in the background. to stop them run './stop_collector.sh'" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}" "" " " "0"
fi

logger " " "header_blue" "1" "1" "${pssdiag_log:-/dev/null}" "" " " "0" #empty line

exit 0
