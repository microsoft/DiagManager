#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

# function definitions


sql_stop_xevent()
{
if [[ $COLLECT_EXTENDED_EVENTS == [Yy][eE][sS]  ]]; then
	echo -e "$(date -u +"%T %D") Stopping Extended events Collection if started..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1)  -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"pssdiag_xevent_stop.sql" -o"$outputdir/${1}_${2}_Stop_XECollection.out"
fi
}

sql_stop_trace()
{
if [[ $COLLECT_SQL_TRACE == [Yy][eE][sS]  ]]; then
        echo -e "$(date -u +"%T %D") Stopping SQL Trace Collection if started..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1)  -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"pssdiag_trace_stop.sql" -o"$outputdir/${1}_${2}_Stop_TraceCollection.out"
fi
}

sql_collect_xevent()
{
if [[ $COLLECT_EXTENDED_EVENTS == [Yy][eE][sS]  ]]; then
        echo -e "$(date -u +"%T %D") Collecting Extended events..." | tee -a $pssdiag_log
	docker exec $1 sh -c "cd /var/opt/mssql/log  && tar cf /tmp/sql_xevent.tar *pssdiag_xevent*.xel "
        docker cp $1:/tmp/sql_xevent.tar ${outputdir}/${2}_${3}_sql_xevent.tar | 2>/dev/null
        docker exec $1 sh -c "rm -f /tmp/sql_xevent.tar"
fi
}

sql_collect_trace()
{
if [[ $COLLECT_SQL_TRACE == [Yy][eE][sS]  ]]; then
        echo -e "$(date -u +"%T %D") Collecting SQL Trace..." | tee -a $pssdiag_log
        docker exec $1 sh -c "cd /var/opt/mssql/log  && tar cf /tmp/sql_trace.tar *pssdiag_trace*.trc "
        docker cp $1:/tmp/sql_trace.tar ${outputdir}/${2}_${3}_sql_trace.tar | 2>/dev/null
        docker exec $1 sh -c "rm -f /tmp/sql_trace.tar"
fi
}

sql_collect_alwayson()
{
if [[ $COLLECT_SQL_HA_LOGS == [Yy][eE][sS]  ]]; then
        echo -e "$(date -u +"%T %D") Collecting SQL AlwaysOn configuration at Shutdown..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1)  -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_AlwaysOnDiagScript.sql" -o"$outputdir/${1}_${2}_SQL_AlwaysOnDiag_Shutdown.out"
fi
}

sql_collect_querystore()
{
if [[ $COLLECT_QUERY_STORE == [Yy][eE][sS]  ]]; then
        echo -e "$(date -u +"%T %D") Collecting SQL Query Store information at Shutdown..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1)  -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_QueryStore.sql" -o"$outputdir/${1}_${2}_SQL_QueryStore_Shutdown.out"
fi
}

sql_collect_perfstats_snapshot()
{
        echo -e "$(date -u +"%T %D") Collecting SQL Perf Stats Snapshot at Shutdown..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1)  -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Perf_Stats_Snapshot.sql" -o"$outputdir/${1}_${2}_SQL_Perf_Stats_Snapshot_Shutdown.out"
}

sql_collect_config()
{
	echo -e "$(date -u +"%T %D") Collecting SQL Configuration Snapshot at Shutdown..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1)  -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Configuration.sql" -o"$outputdir/${1}_${2}_SQL_Configuration_Shutdown.out"
}

sql_collect_linux_snapshot()
{
        echo -e "$(date -u +"%T %D") Collecting SQL Linux Snapshot at Shutdown..." | tee -a $pssdiag_log
        $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1)  -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -i"SQL_Linux_Snapshot.sql" -o"$outputdir/${1}_${2}_SQL_Linux_Snapshot_Shutdown.out"
}

# end of function definitions

##############################
# Start of main script
#############################

authentication_mode=${1^^}

pssdiag_inside_container_get_instance_status

#Checks: make sure we have a valid authentication entered, we are running with system that has systemd
if [[ ! -z "$authentication_mode" ]] && [[ $is_instance_inside_container_active == "NO" ]] && [[ "$authentication_mode" != "SQL" ]] && [[ "$authentication_mode" != "AD" ]] && [[ "$authentication_mode" != "NONE" ]]; then
	echo -e "\x1B[33mwarning: wrong authentication mode (first argument passed to PSSDiag)\x1B[0m"
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
	echo -e "\x1B[33mwarning: wrong authentication mode (first argument passed to PSSDiag)\x1B[0m"
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

echo -e "\x1B[2;34m============================================= Stopping PSSDiag =============================================\x1B[0m" | tee -a $pssdiag_log

if [[ -f $outputdir/pssdiag_stoppids_sql_collectors.txt ]]; then
	echo "$(date -u +"%T %D") Starting to stop background processes that were collecting sql data..." | tee -a $pssdiag_log
	#cat $outputdir/pssdiag_stoppids_sql_collectors.txt
	kill -9 `cat $outputdir/pssdiag_stoppids_sql_collectors.txt` 2> /dev/null
        killedlist=$(awk '{ for (i=1; i<=NF; i++) RtoC[i]= (RtoC[i]? RtoC[i] FS $i: $i) } END{ for (i in RtoC) print RtoC[i] }' $outputdir/pssdiag_stoppids_sql_collectors.txt)
        echo "$(date -u +"%T %D") Stopping the following PIDs $killedlist" | tee -a $pssdiag_log
	#rm -f $outputdir/pssdiag_stoppids_sql_collectors.txt 2> /dev/null
fi
if [[ -f $outputdir/pssdiag_stoppids_os_collectors.txt ]]; then
	echo "$(date -u +"%T %D") Starting to stop background processes that were collecting os data..." | tee -a $pssdiag_log
	#cat $outputdir/pssdiag_stoppids_os_collectors.txt
	kill -9 `cat $outputdir/pssdiag_stoppids_os_collectors.txt` 2> /dev/null
        killedlist=$(awk '{ for (i=1; i<=NF; i++) RtoC[i]= (RtoC[i]? RtoC[i] FS $i: $i) } END{ for (i in RtoC) print RtoC[i] }' $outputdir/pssdiag_stoppids_os_collectors.txt)
        echo "$(date -u +"%T %D") Stopping the following PIDs $killedlist" | tee -a $pssdiag_log
	#rm -f $outputdir/pssdiag_stoppids_os_collectors.txt 2> /dev/null
fi

CONFIG_FILE="./pssdiag_collector.conf"
# echo -e "$(date -u +"%T %D") Reading configuration values from Config file $CONFIG_FILE..." | tee -a $pssdiag_log
if [[ -f $CONFIG_FILE ]]; then
. $CONFIG_FILE
fi

# Specify the defaults here if not specified in config file.
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
if [[ ${authentication_mode} == "SQL" ]] || [[ ${authentication_mode} == "AD" ]] || [[ ${authentication_mode} == "NONE" ]]; then
	SQL_CONNECT_AUTH_MODE=${authentication_mode:-"SQL"}
fi

#this section will connect to sql server instances and collect sql script outputs
#host instance
if [[ "$COLLECT_HOST_SQL_INSTANCE" == "YES" ]];then
        #we collect information from base host instance of SQL Server
        get_host_instance_status
	if [ "${is_host_instnace_service_active}" == "YES" ]; then
                SQL_LISTEN_PORT=$(get_sql_listen_port "host_instance")
                SQL_SERVER_NAME="$HOSTNAME,$SQL_LISTEN_PORT"
                echo -e "" | tee -a $pssdiag_log
                echo -e "\x1B[7mCollecting information from host instance $HOSTNAME and port $SQL_LISTEN_PORT...\x1B[0m" | tee -a $pssdiag_log
                sql_connect "host_instance" "${HOSTNAME}" "${SQL_LISTEN_PORT}" "${authentication_mode}"
                sqlconnect=$?
                if [[ $sqlconnect -ne 1 ]]; then
        	        echo -e "\x1B[31mTesting the connection to host instance using $authentication_mode authentication failed." | tee -a $pssdiag_log
			echo -e "Please refer to the above lines for errors...\x1B[0m" | tee -a $pssdiag_log
                else
                        sql_stop_xevent "${HOSTNAME}" "host_instance" 
                        sql_stop_trace "${HOSTNAME}" "host_instance" 
                        sql_collect_config "${HOSTNAME}" "host_instance"
                        sql_collect_linux_snapshot "${HOSTNAME}" "host_instance"
                  	sql_collect_perfstats_snapshot "${HOSTNAME}" "host_instance"
                        #chown only if pattern exists.
                        stat -t -- $output/*.xel >/dev/null 2>&1 && chown $USER: $outputdir/*.xel
                        # *.xel and *.trc files are placed in the output folder, nothing to collect here 
                        sql_collect_alwayson "${HOSTNAME}" "host_instance"
                        sql_collect_querystore "${HOSTNAME}" "host_instance"
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
                echo -e "\x1B[7mCollecting information from instance $HOSTNAME and port 1433...\x1B[0m" | tee -a $pssdiag_log
                sql_connect "instance" "${HOSTNAME}" "1433" "${authentication_mode}"
                sqlconnect=$?
                if [[ $sqlconnect -ne 1 ]]; then
        	        echo -e "\x1B[31mTesting the connection to instance using $authentication_mode authentication failed." | tee -a $pssdiag_log
			echo -e "Please refer to the above lines for errors...\x1B[0m" | tee -a $pssdiag_log
                else
                        sql_stop_xevent "${HOSTNAME}" "instance" 
                        sql_stop_trace "${HOSTNAME}" "instance" 
                        #chown only if pattern exists.
                        stat -t -- $output/*.xel >/dev/null 2>&1 && chown $USER: $outputdir/*.xel
                        # *.xel and *.trc files are placed in the output folder, nothing to collect here 
                        sql_collect_alwayson "${HOSTNAME}" "instance"
                        sql_collect_querystore "${HOSTNAME}" "instance"
                        sql_collect_config "${HOSTNAME}" "instance"
                        sql_collect_linux_snapshot "${HOSTNAME}" "instance"
                        sql_collect_perfstats_snapshot "${HOSTNAME}" "instance"
                fi
        fi  
fi

echo -e "" | tee -a $pssdiag_log

if [[ "$COLLECT_CONTAINER" != "NO" ]]; then
# we need to collect logs from containers
        get_container_instance_status
        if [ "${is_container_runtime_service_active}" == "YES" ]; then
                if [[ "$COLLECT_CONTAINER" != "ALL" ]]; then
                # we need to process just the specific container
                        dockerid=$(docker ps -q --filter name=$COLLECT_CONTAINER)
                        #moved to helper function
                        get_docker_mapped_port "${dockerid}"
                        #SQL_SERVER_NAME="$HOSTNAME,$dockerport"    
                        SQL_SERVER_NAME="$dockername,$dockerport"
                        echo -e "" | tee -a $pssdiag_log
                        echo -e "\x1B[7mCollecting information from container instance ${dockername} and port ${dockerport}\x1B[0m" | tee -a $pssdiag_log
                        sql_connect "container_instance" "${dockername}" "${dockerport}" "${authentication_mode}"
                        sqlconnect=$?
                        if [[ $sqlconnect -ne 1 ]]; then
                                echo -e "\x1B[31mTesting the connection to container instance using $authentication_mode authentication failed." | tee -a $pssdiag_log
                                echo -e "Please refer to the above lines for errors...\x1B[0m" | tee -a $pssdiag_log
                        else
                                sql_stop_xevent "${dockername}" "container_instance" 
                                sql_stop_trace "${dockername}" "container_instance" 
                                sql_collect_xevent "${dockerid}" "${dockername}" "container_instance"
                                sql_collect_trace "${dockerid}" "${dockername}" "container_instance"
                                sql_collect_alwayson "${dockername}" "container_instance"
                                sql_collect_querystore "${dockername}" "container_instance"
                                sql_collect_config "${dockername}" "container_instance"
                                sql_collect_linux_snapshot "${dockername}" "container_instance"
                                sql_collect_perfstats_snapshot "${dockername}" "container_instance"
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
                                echo -e "" | tee -a $pssdiag_log
                                echo -e "\x1B[7mCollecting information from container instance ${dockername} and port ${dockerport}\x1B[0m" | tee -a $pssdiag_log
                                sql_connect "container_instance" "${dockername}" "${dockerport}" "${authentication_mode}"
                                sqlconnect=$?
                                if [[ $sqlconnect -ne 1 ]]; then
                                        echo -e "\x1B[31mTesting the connection to container instance using $authentication_mode authentication failed." | tee -a $pssdiag_log
                                        echo -e "Please refer to the above lines for errors...\x1B[0m" | tee -a $pssdiag_log
                                else
                                        sql_stop_xevent "${dockername}" "container_instance" 
                                        sql_stop_trace "${dockername}" "container_instance" 
                                        sql_collect_xevent "${dockerid}" "${dockername}" "container_instance"
                                        sql_collect_trace "${dockerid}" "${dockername}" "container_instance"
                                        sql_collect_alwayson "${dockername}" "container_instance"
                                        sql_collect_querystore "${dockername}" "container_instance"
                                        sql_collect_config "${dockername}" "container_instance"
                                        sql_collect_linux_snapshot "${dockername}" "container_instance"
                                        sql_collect_perfstats_snapshot "${dockername}" "container_instance"
                                fi
                        done;
                # we finished processing all the container
                fi
        fi
fi

echo -e "" | tee -a $pssdiag_log

echo -e "\x1B[2;34m======================================== Collecting Static Logs ============================================\x1B[0m" | tee -a $pssdiag_log

#collect basic machine configuration
if [[ $COLLECT_OS_CONFIG == "YES" ]]; then
        ./collect_machineconfig.sh
        ./collect_container_info.sh
fi

#gather os logs from host
if [[ "$COLLECT_OS_LOGS" == "YES" ]]; then
	./collect_os_logs.sh
fi

#Gather pcs logs
if [[ "$COLLECT_OS_HA_LOGS" == "YES" ]]; then
	./collect_os_ha_logs.sh
fi

#Gather krb5 and sssd logs from host 
if [[ "$COLLECT_OS_SEC_AD_LOGS" == "YES" ]]; then
	./collect_os_ad_logs.sh
fi

#gather sql logs from containers or host
if [[ "$COLLECT_SQL_LOGS" == "YES" ]]; then
	./collect_sql_logs.sh
fi
#gather sql dumps from containers or host
if [[ "$COLLECT_SQL_DUMPS" == "YES" ]]; then
	./collect_sql_dumps.sh
fi
#gather SQL Security and AD logs from containers or host
if [[ "$COLLECT_SQL_SEC_AD_LOGS" == "YES" ]]; then
	./collect_sql_ad_logs.sh
fi

echo -e "\x1B[2;34m=======================================  Creating Compressed Archive =======================================\x1B[0m" | tee -a $pssdiag_log
#zip up output directory
tar -zcf "output_${HOSTNAME}_${NOW}.tar.bz2" output
echo -e "***Data collected is in the file output_${HOSTNAME}_${NOW}.tar.bz2 ***" | tee -a $pssdiag_log
echo -e "\x1B[2;34m=================================================== Done ===================================================\x1B[0m" | tee -a $pssdiag_log


