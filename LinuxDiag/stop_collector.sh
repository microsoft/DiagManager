#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

# function definitions


sql_stop_xevent()
{
        if [[ $COLLECT_EXTENDED_EVENTS == [Yy][eE][sS] ]]; then
                logger "Stopping Extended events Collection if started" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                "$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"pssdiag_xevent_stop.sql" -o"$outputdir/${1}_${2}_Stop_XECollection.log"
        fi
}

sql_stop_trace()
{
        if [[ $COLLECT_SQL_TRACE == [Yy][eE][sS] ]]; then
                logger "Stopping SQL Trace Collection if started" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                "$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"pssdiag_trace_stop.sql" -o"$outputdir/${1}_${2}_Stop_TraceCollection.log"
        fi
}

#this is only used for container scenario
sql_collect_xevent()
{
        if [[ $COLLECT_EXTENDED_EVENTS == [Yy][eE][sS] ]]; then
                logger "Collecting Extended events" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                docker exec $1 sh -c "cd /tmp  && tar cf /tmp/sql_xevent.tar *pssdiag_xevent*.xel "
                docker cp $1:/tmp/sql_xevent.tar ${outputdir}/${2}_${3}_sql_xevent.tar | 2>/dev/null
                docker exec $1 sh -c "rm -f /tmp/sql_xevent.tar"
                docker exec $1 sh -c "cd /tmp  && rm -f *pssdiag_xevent*.xel"
        fi
}
#this is only used for container scenario
sql_collect_trace()
{
        if [[ $COLLECT_SQL_TRACE == [Yy][eE][sS] ]]; then
                logger "Collecting SQL Trace" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                docker exec $1 sh -c "cd /tmp  && tar cf /tmp/sql_trace.tar *pssdiag_trace*.trc "
                docker cp $1:/tmp/sql_trace.tar ${outputdir}/${2}_${3}_sql_trace.tar | 2>/dev/null
                docker exec $1 sh -c "cd /tmp  && rm -f *pssdiag_trace*.trc"
        fi
}

sql_collect_alwayson()
{
        if [[ $COLLECT_SQL_HA_LOGS == [Yy][eE][sS] ]]; then
                logger "Collecting SQL AlwaysOn configuration at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                "$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_alwaysondiagscript.sql" -o"$outputdir/${1}_${2}_SQL_AlwaysOnDiag_Shutdown.out"
        fi
}

sql_collect_querystore()
{
        if [[ $COLLECT_QUERY_STORE == [Yy][eE][sS] ]]; then
                logger "Collecting SQL Query Store information at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                "$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_querystore.sql" -o"$outputdir/${1}_${2}_SQL_QueryStore_Shutdown.out"
        fi
}

sql_collect_perfstats_snapshot()
{
        if [[ $COLLECT_PERFSTATS_SNAPSHOT == [Yy][eE][sS] ]] ; then
                logger "Collecting SQL Perf Stats Snapshot at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                "$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_perf_stats_snapshot.sql" -o"$outputdir/${1}_${2}_SQL_Perf_Stats_Snapshot_Shutdown.out"
        fi
}

sql_collect_config()
{
	if [[ $COLLECT_SQL_CONFIG == [Yy][eE][sS] ]] ; then
                logger "Collecting SQL Configuration Snapshot at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                "$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_configuration.sql" -o"$outputdir/${1}_${2}_SQL_Configuration_Shutdown.out"

                logger "Collecting SQL traces information at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                "$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_active_profiler_xe_traces.sql" -o"$outputdir/${1}_${2}_SQL_ActiveProfilerXeventTraces.out"

                logger "Collecting SQL MiscDiag information at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                "$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_miscdiaginfo.sql" -o"$outputdir/${1}_${2}_SQL_MiscDiagInfo.out"
        fi
}

sql_collect_linux_snapshot()
{
        if [[ $COLLECT_PERFSTATS_SNAPSHOT == [Yy][eE][sS] ]] ; then
                logger "Collecting SQL Linux Perf Stats Snapshot at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                "$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"sql_linux_perf_stats_snapshot.sql" -o"$outputdir/${1}_${2}_SQL_Linux_Perf_Stats_Snapshot_Shutdown.out"
        fi
}

sql_collect_databases_disk_map()
{
        if [[ $COLLECT_SQL_CONFIG == [Yy][eE][sS] ]] ; then
                logger "Collecting SQL Databases Disk Map information at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                ./collect_sql_database_disk_map.sh "$SQL_SERVER_NAME" "$CONN_AUTH_OPTIONS" >> $outputdir/${1}_${2}_SQL_Databases_Disk_Map_Shutdown.out
        fi
}

sql_collect_known_issues_analyzer()
{
        if [[ $COLLECT_SQL_CONFIG == [Yy][eE][sS] ]] ; then
                logger "Collecting SQL Known Issues Analyzer information at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                ./sql_linux_known_issues_analyzer.sh "$SQL_SERVER_NAME" "$CONN_AUTH_OPTIONS" >> $outputdir/${1}_${2}_SQL_Linux_Known_Issues_Analyzer.out
        fi
}

sql_collect_top_plans_CPU()
{
        if [[ $COLLECT_PERFSTATS_SNAPSHOT == [Yy][eE][sS] ]] ; then
                logger "Collecting TOP CPU Plans at Shutdown" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                for i in {1..10}
                do
                TOP10PLANS_QUERY=$"SET NOCOUNT ON;SELECT xmlplan FROM (
                        SELECT ROW_NUMBER() OVER(ORDER BY (highest_cpu_queries.total_worker_time/highest_cpu_queries.execution_count) DESC) AS RowNumber,
                        CAST(query_plan AS XML) xmlplan
                        FROM (
                        SELECT TOP 10 qs.plan_handle, qs.total_worker_time, qs.execution_count
                        FROM sys.dm_exec_query_stats qs
                        ORDER BY qs.total_worker_time DESC
                        ) AS highest_cpu_queries
                        CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS q
                        CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS p
                ) AS x
                WHERE RowNumber = $i"
                "$SQLCMD" -S"$SQL_SERVER_NAME" $CONN_AUTH_OPTIONS -C -y 0 -Q "$TOP10PLANS_QUERY" > "$outputdir/${1}_${2}_Top_CPU_QueryPlansXml_Shutdown_${i}.sqlplan"
                done
        fi
}
 

#########################
# Start of main script  #
# - Stop_collector.sh   #
#########################

authentication_mode=${1^^}

pssdiag_inside_container_get_instance_status
find_sqlcmd


if grep -q "SUDO:YES" "$outputdir/pssdiag_intiated_as_user.log"; then
    STARTED_WITH_SUDO=true
fi

# Checks: if we run with SUDO and not inside a container, and provide the warning.
if [ -z "$SUDO_USER" ] && [ "$is_instance_inside_container_active" = "NO" ] && [ "$STARTED_WITH_SUDO" = true ]; then
	echo -e "\e[31mWarning: PSSDiag was initiated with elevated (sudo) permissions.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
        echo -e "\e[31mHowever, PSSDiag Stop was not initiated wtih elevated (sudo) permissions.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	echo -e "\e[31mElevated (sudo) permissions are required for PSSDiag to stop the collectors that are currently.\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
        echo -e "\e[31mexisting... .\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
        echo -e "" | tee -a "$pssdiag_log"
	echo -e "\e[31mPlease run 'sudo ./stop_collector.sh' .\e[0m" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$pssdiag_log")
	exit 1
fi

#Checks: make sure we have a valid authentication entered, we are running with system that has systemd
if [[ ! -z "$authentication_mode" ]] && [[ $is_instance_inside_container_active == "NO" ]] && [[ "$authentication_mode" != "SQL" ]] && [[ "$authentication_mode" != "AD" ]] && [[ "$authentication_mode" != "NONE" ]]; then
	echo -e "\x1B[33mwarning: Invalid authentication mode (first argument passed to PSSDiag)\x1B[0m"
	echo "" 
	echo "Valid options are:" 
	echo "  SQL"
	echo "  AD"
	echo "  NONE"
	echo "" 
	echo -e "\x1B[33mIgnoring the entry, PSSDiag will ask you which Authentication Mode to use...\x1B[0m" 
	exit 1	
fi

#Checks: make sure we have a valid authentication entered, we are running with system that has no systemd
if [[ ! -z "$authentication_mode" ]] && [[ $is_instance_inside_container_active == "YES" ]] && [[ "$authentication_mode" != "SQL" ]]; then
	echo -e "\x1B[33mwarning: Invalid authentication mode (first argument passed to PSSDiag)\x1B[0m"
	echo "" 
	echo "Valid options are:" 
	echo "  SQL"
	echo "" 
	echo -e "\x1B[33mIgnoring the entry, PSSDiag will use 'SQL' Authentication Mode...\x1B[0m" 
fi

outputdir="$PWD/output"
NOW=`date +"%m_%d_%Y_%H_%M"`
#credentials to collect shutdown script

# Read the PID we stored from the Start of the script
# kills all the PID's stored in the file
# after all work is done, remove the PID files

# ──────────────────────────────────
# Cleanup
# - Clean up background processes
# ──────────────────────────────────

if [[ -f $outputdir/pssdiag_stoppids_sql_collectors.log ]] || [[ -f $outputdir/pssdiag_stoppids_os_collectors.log ]]; then
       logger "Stopping background processes" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
fi

if [[ -f $outputdir/pssdiag_stoppids_sql_collectors.log ]]; then
	logger "Starting to stop background processes that were collecting sql data" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	#cat $outputdir/pssdiag_stoppids_sql_collectors.log
	kill -9 `cat $outputdir/pssdiag_stoppids_sql_collectors.log` 2> /dev/null
        killedlist=$(awk '{ for (i=1; i<=NF; i++) RtoC[i]= (RtoC[i]? RtoC[i] FS $i: $i) } END{ for (i in RtoC) print RtoC[i] }' $outputdir/pssdiag_stoppids_sql_collectors.log)
        logger "Stopping the following PIDs $killedlist" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	#rm -f $outputdir/pssdiag_stoppids_sql_collectors.log 2> /dev/null
fi
if [[ -f $outputdir/pssdiag_stoppids_os_collectors.log ]]; then
        logger "Starting to stop background processes that were collecting host data" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	#cat $outputdir/pssdiag_stoppids_os_collectors.log
	kill -9 `cat $outputdir/pssdiag_stoppids_os_collectors.log` 2> /dev/null
        killedlist=$(awk '{ for (i=1; i<=NF; i++) RtoC[i]= (RtoC[i]? RtoC[i] FS $i: $i) } END{ for (i in RtoC) print RtoC[i] }' $outputdir/pssdiag_stoppids_os_collectors.log)
        logger "Stopping the following PIDs $killedlist" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	#rm -f $outputdir/pssdiag_stoppids_os_collectors.log 2> /dev/null
fi


logger "Starting Static Collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

# ────────────────────────────
# Config section
# - read config values
# ────────────────────────────
CONFIG_FILE="./pssdiag_collector.conf"
if [[ -f $CONFIG_FILE ]]; then
. $CONFIG_FILE
fi

# Specify the defaults here if not specified in config file.
COLLECT_HOST_OS_INFO=${COLLECT_HOST_OS_INFO:-"NO"}
COLLECT_HOST_SQL_INSTANCE=${COLLECT_HOST_SQL_INSTANCE:-"NO"}
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"NO"}
COLLECT_SQL_DUMPS=${COLLECT_SQL_DUMPS:-"NO"}
COLLECT_SQL_LOGS=${COLLECT_SQL_LOGS:-"NO"}
COLLECT_OS_LOGS=${COLLECT_OS_LOGS:-"NO"}
COLLECT_OS_CONFIG=${COLLECT_OS_CONFIG:-"NO"}
COLLECT_EXTENDED_EVENTS=${COLLECT_EXTENDED_EVENTS:-"NO"}
COLLECT_SQL_TRACE=${COLLECT_SQL_TRACE:-"NO"}
COLLECT_QUERY_STORE=${COLLECT_QUERY_STORE:-"NO"}
COLLECT_SQL_HA_LOGS=${COLLECT_SQL_HA_LOGS:-"NO"}
COLLECT_SQL_SEC_AD_LOGS=${COLLECT_SQL_SEC_AD_LOGS:-"NO"}
COLLECT_SQL_BEST_PRACTICES=${COLLECT_SQL_BEST_PRACTICES:-"NO"}
if [[ ${authentication_mode} == "SQL" ]] || [[ ${authentication_mode} == "AD" ]] || [[ ${authentication_mode} == "NONE" ]]; then
	SQL_CONNECT_AUTH_MODE=${authentication_mode:-"SQL"}
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

if [[ $COLLECT_HOST_SQL_INSTANCE == [Yy][eE][sS] ]];then
        #we collect information from base host instance of SQL Server
        get_host_instance_status
	if [[ "${is_host_instance_process_running}" == [Yy][eE][sS] ]]; then
                SQL_LISTEN_PORT=$(get_sql_listen_port "host_instance")
                SQL_SERVER_NAME="$HOSTNAME,$SQL_LISTEN_PORT"
                timeout 15 bash -c "echo > /dev/tcp/$HOSTNAME/$SQL_LISTEN_PORT" 2>/dev/null

                #if no errors, go ahead and try to connect            
                if [ $? -eq 0 ]; then
                        logger "Collecting information from host instance $HOSTNAME and port $SQL_LISTEN_PORT" "info_highlight" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                        sql_connect "host_instance" "${HOSTNAME}" "${SQL_LISTEN_PORT}" "${authentication_mode}"
                        sqlconnect=$?
                        if [[ $sqlconnect -ne 1 ]]; then
                                logger "Connection to host instance using $authentication_mode authentication failed." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                                logger "Please refer to the above lines for errors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                                logger "Skipping static TSQL based collectors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                        else
                                sql_stop_xevent "${HOSTNAME}" "host_instance" 
                                sql_stop_trace "${HOSTNAME}" "host_instance" 

                                logger "Starting static TSQL Based collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

                                sql_collect_config "${HOSTNAME}" "host_instance"
                                sql_collect_top_plans_CPU "${HOSTNAME}" "host_instance"
                                sql_collect_linux_snapshot "${HOSTNAME}" "host_instance"
                                sql_collect_perfstats_snapshot "${HOSTNAME}" "host_instance"
                                #chown only if pattern exists.
                                stat -t -- $output/*.xel >/dev/null 2>&1 && chown $USER: $outputdir/*.xel  
                                # *.xel and *.trc files are placed in the output folder, nothing to collect here 
                                sql_collect_alwayson "${HOSTNAME}" "host_instance"
                                sql_collect_querystore "${HOSTNAME}" "host_instance"
                                sql_collect_databases_disk_map "${HOSTNAME}" "host_instance" #this is only for host_instance scenario 
                                sql_collect_known_issues_analyzer "${HOSTNAME}" "host_instance"
                        fi
                else
                        logger "there is no SQL instance listening on port $SQL_LISTEN_PORT, skipping TSQL based collectors..." "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                fi
        fi
fi

# ──────────────────────────────────────
# - Collect "instance"                   
# - SQL running inside container
# - PSSDiag is running inside container       
# ──────────────────────────────────────

if [[ $COLLECT_HOST_SQL_INSTANCE == [Yy][eE][sS] ]];then
	pssdiag_inside_container_get_instance_status
	if [[ "${is_instance_inside_container_active}" == [Yy][eE][sS] ]]; then
                SQL_SERVER_NAME="$HOSTNAME,1433"
                logger "Collecting information from instance $HOSTNAME and port 1433" "info_highlight" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                sql_connect "instance" "${HOSTNAME}" "1433" "${authentication_mode}"
                sqlconnect=$?
                if [[ $sqlconnect -ne 1 ]]; then
                        logger "Connection to instance using $authentication_mode authentication failed." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                        logger "Please refer to the above lines for errors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                        logger "Skipping static TSQL based collectors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                else
                        sql_stop_xevent "${HOSTNAME}" "instance" 
                        sql_stop_trace "${HOSTNAME}" "instance" 

                        logger "Starting Static TSQL Based collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

                        #chown only if pattern exists.
                        stat -t -- $output/*.xel >/dev/null 2>&1 && chown $USER: $outputdir/*.xel  
                        # *.xel and *.trc files are placed in the output folder, nothing to collect here 
                        sql_collect_alwayson "${HOSTNAME}" "instance"
                        sql_collect_querystore "${HOSTNAME}" "instance"
                        sql_collect_config "${HOSTNAME}" "instance"
                        sql_collect_top_plans_CPU "${HOSTNAME}" "instance"
                        sql_collect_linux_snapshot "${HOSTNAME}" "instance"
                        sql_collect_perfstats_snapshot "${HOSTNAME}" "instance"
                        sql_collect_known_issues_analyzer "${HOSTNAME}" "instance"
                fi
        fi  
fi


# ──────────────────────────────────────
# - Collect "container_instance"                   
# - SQL running as docker container
# - PSSDiag is running on VM       
# ──────────────────────────────────────

if [[ $COLLECT_CONTAINER != [Nn][Oo] ]]; then
# we need to collect logs from containers
        get_container_instance_status
        if [ "${is_container_runtime_service_active}" == "YES" ]; then
                if [[ $COLLECT_CONTAINER != [Aa][Ll][Ll] ]]; then
                # we need to process just the specific container
                        dockerid=$(docker ps -q --filter name=$COLLECT_CONTAINER)
                        #moved to helper function
                        get_docker_mapped_port "${dockerid}"
                        #SQL_SERVER_NAME="$HOSTNAME,$dockerport"    
                        SQL_SERVER_NAME="$dockername,$dockerport"
                        logger "Collecting information from container instance ${dockername} and port ${dockerport}" "info_highlight" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                        sql_connect "container_instance" "${dockername}" "${dockerport}" "${authentication_mode}"
                        sqlconnect=$?
                        if [[ $sqlconnect -ne 1 ]]; then
                                logger "Connection to container instance using $authentication_mode authentication failed." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                                logger "Please refer to the above lines for errors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                                logger "Skipping static TSQL based collectors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                        else
                                sql_stop_xevent "${dockername}" "container_instance"
                                sql_stop_trace "${dockername}" "container_instance"

                                logger "Starting Static TSQL Based collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

                                sql_collect_xevent "${dockerid}" "${dockername}" "container_instance"
                                sql_collect_trace "${dockerid}" "${dockername}" "container_instance"
                                sql_collect_alwayson "${dockername}" "container_instance"
                                sql_collect_querystore "${dockername}" "container_instance"
                                sql_collect_config "${dockername}" "container_instance"
                                sql_collect_top_plans_CPU "${dockername}" "container_instance"
                                sql_collect_linux_snapshot "${dockername}" "container_instance"
                                sql_collect_perfstats_snapshot "${dockername}" "container_instance"
                                sql_collect_known_issues_analyzer "${dockername}" "container_instance" 
                        fi
                # we finished processing the requested container
                else
                # we need to iterate through all containers
                        #dockerid_col=$(docker ps | grep 'microsoft/mssql-server-linux' | awk '{ print $1 }')
                        dockerid_col=$(docker ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }')

                        for dockerid in $dockerid_col;
                        do
                                #moved to helper function
                                get_docker_mapped_port "${dockerid}"
                                SQL_SERVER_NAME="$dockername,$dockerport"
                                logger "Collecting information from container instance ${dockername} and port ${dockerport}" "info_highlight" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                                sql_connect "container_instance" "${dockername}" "${dockerport}" "${authentication_mode}"
                                sqlconnect=$?
                                if [[ $sqlconnect -ne 1 ]]; then
                                        logger "Connection to container instance using $authentication_mode authentication failed." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                                        logger "Please refer to the above lines for errors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                                        logger "Skipping static TSQL based collectors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
                                else
                                        sql_stop_xevent "${dockername}" "container_instance"
                                        sql_stop_trace "${dockername}" "container_instance"

                                        logger "Starting Static TSQL Based collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

                                        sql_collect_xevent "${dockerid}" "${dockername}" "container_instance"
                                        sql_collect_trace "${dockerid}" "${dockername}" "container_instance"
                                        sql_collect_alwayson "${dockername}" "container_instance"
                                        sql_collect_querystore "${dockername}" "container_instance"
                                        sql_collect_config "${dockername}" "container_instance"
                                        sql_collect_top_plans_CPU "${dockername}" "container_instance"
                                        sql_collect_linux_snapshot "${dockername}" "container_instance"
                                        sql_collect_perfstats_snapshot "${dockername}" "container_instance"
                                        sql_collect_known_issues_analyzer "${dockername}" "container_instance"
                                fi
                        done;
                # we finished processing all the container
                fi
        fi
fi

######################################################################################
# bash script collectors                                                             #
# - this section will use sh script to collect logs and configuration                #
######################################################################################

logger "Starting Static Logs Collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

#collect basic machine configuration
if [[ $COLLECT_HOST_OS_INFO == [Yy][eE][sS] && $COLLECT_OS_CONFIG == [Yy][eE][sS] ]]; then
        ./collect_machineconfig.sh
        ./collect_container_info.sh
fi

#gather os logs from host
if [[ $COLLECT_HOST_OS_INFO == [Yy][eE][sS] && $COLLECT_OS_LOGS == [Yy][eE][sS] ]]; then
	./collect_os_logs.sh
fi

#Gather pcs logs
if [[ $COLLECT_HOST_OS_INFO == [Yy][eE][sS] && $COLLECT_OS_HA_LOGS == [Yy][eE][sS] ]]; then
	./collect_os_ha_logs.sh
fi

#Gather krb5 and sssd logs from host
if [[ $COLLECT_HOST_OS_INFO == [Yy][eE][sS] && $COLLECT_OS_SEC_AD_LOGS == [Yy][eE][sS] ]]; then
	./collect_os_ad_logs.sh
fi

#gather sql logs from containers or host
#we will check for COLLECT_CONTAINER and COLLECT_HOST_SQL_INSTANCE inside the script, since its one script that collects from both places
if [[ $COLLECT_SQL_LOGS == [Yy][eE][sS] ]]; then
	./collect_sql_logs.sh
fi
#gather sql dumps from containers or host
#we will check for COLLECT_CONTAINER and COLLECT_HOST_SQL_INSTANCE inside the script, since its one script that collects from both places
if [[ $COLLECT_SQL_DUMPS == [Yy][eE][sS] ]]; then
	./collect_sql_dumps.sh
fi
#gather SQL Security and AD logs from containers or host
#we will check for COLLECT_CONTAINER and COLLECT_HOST_SQL_INSTANCE inside the script, since its one script that collects from both places
if [[ $COLLECT_SQL_SEC_AD_LOGS == [Yy][eE][sS] ]]; then
	./collect_sql_ad_logs.sh
fi

#gather SQL Best Practices Analyzer
#we will check for COLLECT_CONTAINER and COLLECT_HOST_SQL_INSTANCE inside the script, since its one script that collects from both places
if [[ $COLLECT_SQL_BEST_PRACTICES == [Yy][eE][sS] ]]; then
        logger "Collecting SQL Linux Best Practices Analyzer" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        ./sql_linux_best_practices_analyzer.sh --explain-all >> $outputdir/${HOSTNAME}_host_instance_SQL_Linux_Best_Practice_Analyzer.out
fi

if [ "$EUID" -ne 0 ]; then

#empty line
logger "Collection Completed, Getting the content of the output folder... " "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger " " "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}"  "" " " "0"

# for minimal collecton, where user didnt use sudo, we cant compress the output file as it may contains files with mssql user, like XEL and TRC files.
  logger "#" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}"  "" "#" "0"
  logger "Data collected in the output folder, Compress the output folder with sudo to include all the files." "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}"  "" " " "1"
  logger "#" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}"  "" "#" "0"
  exit 0
fi

#empty line
logger "Collection Completed, Getting the content of the output folder..." "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
logger " " "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}"  "" " " "0"

logger "Creating Compressed Archive" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}"  "" "#" "0"
#zip up output directory
short_hostname="${HOSTNAME%%.*}"
tar -cjf "output_${short_hostname}_${NOW}.tar.bz2" output
logger "Created the compressed archive output_${short_hostname}_${NOW}.tar.bz2" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}"  "" " " "1"
logger "#" "header_yellow" "1" "1" "${pssdiag_log:-/dev/null}"  "" "#" "0"

exit 0
 



