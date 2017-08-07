#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

# function definitions

sql_collect_perfstats()
{
	echo "	Collecting PerfStats Snapshot script at Shutdown..."
        /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"SQL_Configuration.sql" -o"$outputdir/${1}_SQL_Configuration_Shutdown.out"
}

sql_stop_xevent()
{
	echo "	Stopping XE Collection if started..."
        /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"pssdiag_xevent_stop.sql" -o"$outputdir/${1}_Stop_XECollection.out"
}

sql_collect_xevent()
{
	docker exec $1 sh -c "cd /var/opt/mssql/log  && tar cf /tmp/sql_xevent.tar *pssdiag_xevent*.xel "
        docker cp $1:/tmp/sql_xevent.tar ${outputdir}/${2}_sql_xevent.tar
        docker exec $1 sh -c "rm -f /tmp/sql_xevent.tar"
}

# end of function definitions

outputdir="$PWD/output"
NOW=`date +"%m_%d_%Y_%H_%M"`
#credentials to collect shutdown script

echo "Terminating the following Background processes that were collecting data... Please wait."
# Read the PID we stored from the Start of the script
cat stoppids_sql_collectors.txt
cat stoppids_os_collectors.txt

#kills all the specified PIDS
kill -9 `cat stoppids_sql_collectors.txt` 2> /dev/null
kill -9 `cat stoppids_os_collectors.txt` 2> /dev/null

#remove the PID files
rm -f stoppids_sql_collectors.txt 2> /dev/null
rm -f stoppids_os_collectors.txt 2> /dev/null

CONFIG_FILE="./pssdiag_collector.conf"
echo "Reading configuration values from Config file $CONFIG_FILE"
if [[ -f $CONFIG_FILE ]]; then
. $CONFIG_FILE
fi

# Specify the defaults here if not specified in config file.
COLLECT_HOST=${COLLECT_HOST:-"YES"}
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"NO"}
COLLECT_SQL_DUMPS=${COLLECT_SQL_DUMPS:-"NO"}

#gather os logs from host
sudo ./collect_os_logs.sh
#gather sql logs from containers or host
sudo ./collect_sql_logs.sh
#gather sql dumps from containers or host
if [[ "$COLLECT_SQL_DUMPS" = "YES" ]]; then
	sudo ./collect_dumps.sh
fi

#this section will connect to sql server instances and collect sql script outputs
if [[ "$COLLECT_HOST" == "YES" ]];then
        #we collect information from base host instance of SQL Server
        echo "collecting sql scripts from host : $HOSTNAME"
	SQL_LISTEN_PORT=$(get_sql_listen_port "host_instance")
        SQL_SERVER_NAME="$HOSTNAME,$SQL_LISTEN_PORT"
	echo "SQL Scripts collection at shutdown for ${1} with name ${2} and port ${3}"
        sql_connect "host_instance" "${HOSTNAME}" "${SQL_LISTEN_PORT}"
        sqlconnect=$?
        if [[ $sqlconnect -ne 1 ]]; then
                echo "  Connection to SQL Server instance failed, SQL scripts will not be collected. Only OS scripts will be collected"
        else
		sql_collect_perfstats "${HOSTNAME}"
		sql_stop_xevent "${HOSTNAME}"
		 #chown only if pattern exists.
                 stat -t -- $output/*.xel >/dev/null 2>&1 && chown $USER: $outputdir/*.xel
		
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
                        echo "  Connection to SQL Server instance failed, SQL scripts will not be collected. Only OS scripts will be collected"
                else
			sql_collect_perfstats "${dockername}"
			sql_stop_xevent "${dockername}"
			sql_collect_xevent "${dockerid}" "${dockername}"
                fi
        # we finished processing the requested container
        else
        # we need to iterate through all containers
                dockerid_col=$(docker ps -q --filter ancestor=microsoft/mssql-server-linux)
                for dockerid in $dockerid_col;
                do
			#moved to helper function
         		get_docker_mapped_port "${dockerid}"
                        SQL_SERVER_NAME="$HOSTNAME,$dockerport"
                        sql_connect "container_instance" "${dockername}" "${dockerport}"
                        sqlconnect=$?
                        if [[ $sqlconnect -ne 1 ]]; then
                                echo "  Connection to SQL Server instance failed, SQL scripts will not be collected. Only OS scripts will be collected"
                        else
				sql_collect_perfstats "${dockername}"
				sql_stop_xevent "${dockername}"
				sql_collect_xevent "${dockerid}" "${dockername}"
                        fi
                done;
        # we finished processing all the container
        fi
fi

        echo ""
        echo "============Zipping up the logs.. please wait........"
        echo ""
	#zip up output directory
	tar -zcf "output_${HOSTNAME}_${NOW}.tar.bz2" output
	echo -e "\n ***Data collected is in the file output_${HOSTNAME}_${NOW}.tar.bz2 ***"


