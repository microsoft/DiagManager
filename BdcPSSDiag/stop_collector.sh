#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

# function definitions

sql_collect_config()
{
	echo "	Collecting SQL Configuration Snapshot at Shutdown..."
        /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"SQL_Configuration.sql" -o"$outputdir/${1}_SQL_Configuration_Shutdown.out"
}

sql_stop_xevent()
{
if [[ $COLLECT_EXTENDED_EVENTS == [Yy][eE][sS]  ]]; then
	echo "	Stopping XE Collection if started..."
        /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"pssdiag_xevent_stop.sql" -o"$outputdir/${1}_Stop_XECollection.out"
fi
}

sql_stop_trace()
{
if [[ $COLLECT_SQL_TRACE == [Yy][eE][sS]  ]]; then
        echo "	Stopping SQL Trace Collection if started..."
        /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"pssdiag_trace_stop.sql" -o"$outputdir/${1}_Stop_TraceCollection.out"
fi
}

sql_collect_xevent()
{
if [[ $COLLECT_EXTENDED_EVENTS == [Yy][eE][sS]  ]]; then
	docker exec $1 sh -c "cd /var/opt/mssql/log  && tar cf /tmp/sql_xevent.tar *pssdiag_xevent*.xel "
        docker cp $1:/tmp/sql_xevent.tar ${outputdir}/${2}_sql_xevent.tar
        docker exec $1 sh -c "rm -f /tmp/sql_xevent.tar"
fi
}

sql_collect_trace()
{
if [[ $COLLECT_SQL_TRACE == [Yy][eE][sS]  ]]; then
        docker exec $1 sh -c "cd /var/opt/mssql/log  && tar cf /tmp/sql_trace.tar *pssdiag_trace*.trc "
        docker cp $1:/tmp/sql_trace.tar ${outputdir}/${2}_sql_trace.tar
        docker exec $1 sh -c "rm -f /tmp/sql_trace.tar"
fi
}

sql_collect_alwayson()
{
if [[ $COLLECT_SQL_HA_LOGS == [Yy][eE][sS]  ]]; then
        echo "	Collecting SQL AlwaysOn configuration at Shutdown..."
        /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"SQL_AlwaysOnDiagScript.sql" -o"$outputdir/${1}_SQL_AlwaysOnDiag_Shutdown.out"
fi
}

sql_collect_querystore()
{
if [[ $COLLECT_QUERY_STORE == [Yy][eE][sS]  ]]; then
        echo "	Collecting SQL Query Store information at Shutdown..."
        /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"SQL_QueryStore.sql" -o"$outputdir/${1}_SQL_QueryStore_Shutdown.out"
fi
}

# end of function definitions

##############################
# Start of main script
#############################
echo ""

outputdir="$PWD/output"
NOW=`date +"%m_%d_%Y_%H_%M"`
#credentials to collect shutdown script

# Read the PID we stored from the Start of the script
# kills all the PID's stored in the file
# after all work is done, remove the PID files
if [[ -f $outputdir/stoppids_sql_collectors.txt ]]; then
	echo "Terminating the following Background processes that were collecting sql data... Please wait."
	cat $outputdir/stoppids_sql_collectors.txt
	kill -9 `cat $outputdir/stoppids_sql_collectors.txt` 2> /dev/null
	#rm -f $outputdir/stoppids_sql_collectors.txt 2> /dev/null
fi
if [[ -f $outputdir/stoppids_os_collectors.txt ]]; then
	echo "Terminating the following Background processes that were collecting os data... Please wait."
	cat $outputdir/stoppids_os_collectors.txt
	kill -9 `cat $outputdir/stoppids_os_collectors.txt` 2> /dev/null
	#rm -f $outputdir/stoppids_os_collectors.txt 2> /dev/null
fi

CONFIG_FILE="./pssdiag_collector.conf"
echo "Reading configuration values from Config file $CONFIG_FILE"
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


#collect basic machine configuration
if [[ $COLLECT_OS_CONFIG == "YES" ]] ; then
        ./collect_machineconfig.sh
        ./collect_container_info.sh
fi

#gather os logs from host
if [[ "$COLLECT_OS_LOGS" == "YES" ]]; then
	sudo ./collect_os_logs.sh
fi

#gather sql logs from containers or host
if [[ "$COLLECT_SQL_LOGS" == "YES" ]]; then
	sudo ./collect_sql_logs.sh
fi
#gather sql dumps from containers or host
if [[ "$COLLECT_SQL_DUMPS" == "YES" ]]; then
	sudo ./collect_dumps.sh
fi

#this section will connect to sql server instances and collect sql script outputs
if [[ "$COLLECT_HOST_SQL_INSTANCE" == "YES" ]];then
        #we collect information from base host instance of SQL Server
        echo "collecting information from sql instance on host : $HOSTNAME"
	SQL_LISTEN_PORT=$(get_sql_listen_port "host_instance")
        SQL_SERVER_NAME="$HOSTNAME,$SQL_LISTEN_PORT"
        sql_connect "host_instance" "${HOSTNAME}" "${SQL_LISTEN_PORT}"
        sqlconnect=$?
        if [[ $sqlconnect -ne 1 ]]; then
                echo "     Connection to SQL Server instance failed, SQL scripts will not be collected. Only OS scripts will be collected"
        else
		sql_collect_config "${HOSTNAME}"
		sql_stop_xevent "${HOSTNAME}"
		sql_stop_trace "${HOSTNAME}"
		#chown only if pattern exists.
                stat -t -- $output/*.xel >/dev/null 2>&1 && chown $USER: $outputdir/*.xel
		sql_collect_alwayson "${HOSTNAME}"
		sql_collect_querystore "${HOSTNAME}"
	fi
fi

if [[ "$COLLECT_CONTAINER" != "NO" ]]; then
# we need to collect logs from containers
        if [[ "$COLLECT_CONTAINER" != "ALL" ]]; then
        # we need to process just the specific container
                dockerid=$(docker ps -q --filter name=$COLLECT_CONTAINER)
		 #moved to helper function
		get_docker_mapped_port "${dockerid}"
                SQL_SERVER_NAME="$HOSTNAME,$dockerport"    
                sql_connect "container_instance" "${dockername}" "${dockerport}"
                sqlconnect=$?
                if [[ $sqlconnect -ne 1 ]]; then
                        echo "     Connection to SQL Server instance failed, SQL scripts will not be collected. Only OS scripts will be collected"
                else
			sql_collect_config "${dockername}"
			sql_stop_xevent "${dockername}"
			sql_collect_xevent "${dockerid}" "${dockername}"
			sql_stop_trace "${dockername}"
			sql_collect_trace "${dockerid}" "${dockername}"
			sql_collect_alwayson "${dockername}"
			sql_collect_querystore "${dockername}"
                fi
        # we finished processing the requested container
        else
        # we need to iterate through all containers
                dockerid_col=$(docker ps | grep 'microsoft/mssql-server-linux' | awk '{ print $1 }')
                for dockerid in $dockerid_col;
                do
			#moved to helper function
         		get_docker_mapped_port "${dockerid}"
                        SQL_SERVER_NAME="$HOSTNAME,$dockerport"
                        sql_connect "container_instance" "${dockername}" "${dockerport}"
                        sqlconnect=$?
                        if [[ $sqlconnect -ne 1 ]]; then
                                echo "     Connection to SQL Server instance failed, SQL scripts will not be collected. Only OS scripts will be collected"
                        else
				sql_collect_config "${dockername}"
				sql_stop_xevent "${dockername}"
				sql_collect_xevent "${dockerid}" "${dockername}"
				sql_stop_trace "${dockername}"
				sql_collect_trace "${dockerid}" "${dockername}"
        	                sql_collect_alwayson "${dockername}"
	                        sql_collect_querystore "${dockername}"
                        fi
                done;
        # we finished processing all the container
        fi
fi

        echo "============ Creating a compressed archive of all log files ==========="
	#zip up output directory
	tar -zcf "output_${HOSTNAME}_${NOW}.tar.bz2" output
	echo -e "***Data collected is in the file output_${HOSTNAME}_${NOW}.tar.bz2 ***"


