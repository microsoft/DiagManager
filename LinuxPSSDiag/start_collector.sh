#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

# defining all functions upfront

sql_connect()
{
	echo "Testing SQL Connectivity for ${1} with name ${2} and port ${3}"
	MAX_ATTEMPTS=3
	attempt_num=1
	sqlconnect=0
	while [ $attempt_num -le $MAX_ATTEMPTS ]
	do
        	#prompt for credentials for SQL authentication
	        read -r -p "	Enter SQL UserName: " sqluser
        	read -s -r -p "	Enter User Password: " pass
	        echo ""
        	/opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -Q"select @@version" 2>&1 >/dev/null
	        if [[ $? -eq 0 ]]; then
        		sqlconnect=1
	        	echo "	SQL Connectivity test succeeded..."
	        	break
	        else
        		echo "	Login Attempt failed - Attempt ${attempt_num} of ${MAX_ATTEMPTS}, Please try again"
	        fi
        	attempt_num=$(( attempt_num + 1 ))
	done
return $sqlconnect
}

sql_collect_perfstats()
{
        if [[ $COLLECT_PERFSTATS == [Yy][eE][sS] ]] ; then
                #Start regular PerfStats script as a background job
                echo "	Starting SQL Perf Stats script as a background job...."
                `/opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"SQL_Perf_Stats.sql" -o"$outputdir/${1}_SQL_Perf_Stats_Output.out"` &
                mypid=$!
                printf "%s\n" "$mypid" >> stoppids_sql_collectors.txt
                pgrep -P $mypid  >> stoppids_sql_collectors.txt
                `/opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"SQL_DMV_Snapshots.sql" -o"$outputdir/${1}_SQL_DMV_Snapshots.out"` &
                mypid=$!
                printf "%s\n" "$mypid" >> stoppids_sql_collectors.txt
                pgrep -P $mypid  >> stoppids_sql_collectors.txt
        fi
}

sql_collect_counters()
{
        if [[ $COLLECT_SQL_COUNTERS == [Yy][eE][sS] ]] ; then
                #Start sql performance counter script as a background job
                #Replace Interval with SED
                sed -i'' -e"2s/.*/SET @SQL_COUNTER_INTERVAL = $SQL_COUNTERS_INTERVAL/g" SQL_Performance_Counters.sql
                echo "	Starting SQL Performance counter  script as a background job.... "
                `/opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"SQL_Performance_Counters.sql" -o"$outputdir/${1}_SQL_Performance_Counters.out"` &
                mypid=$!
                printf "%s\n" "$mypid" >> stoppids_sql_collectors.txt
                pgrep -P $mypid  >> stoppids_sql_collectors.txt
        fi
}

sql_collect_config()
{
        #include whatever base collector scripts exist here
        echo "	Collecting SQL Configuration information at startup..."
        /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"SQL_Configuration.sql" -o"$outputdir/${1}_SQL_Configuration_Startup.out"
}

sql_collect_memstats()
{
        if [[ $COLLECT_SQL_MEM_STATS == [Yy][eE][sS] ]] ; then
                #Start SQL Memory Status  script as a background job
                echo "	Starting SQL Memory Status  script as a background job.... "
                `/opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"SQL_Mem_Stats.sql" -o"$outputdir/${1}_SQL_Mem_Stats_Output.out"` &
                mypid=$!
                printf "%s\n" "$mypid" >> stoppids_sql_collectors.txt
                pgrep -P $mypid  >> stoppids_sql_collectors.txt
        fi
}

sql_collect_custom()
{
        if [[ $CUSTOM_COLLECTOR == [Yy][eE][sS] ]] ; then
                #Start Custom Collector  scripts as a background job
                echo "	Starting SQL Custom Collector Scripts  as a background job.... "
                for filename in my_custom_collector*.sql; do
                   `/opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"${filename}" -o"$outputdir/${1}_${filename}_Output.out"` &
                    mypid=$!
                    printf "%s\n" "$mypid" >> stoppids_sql_collectors.txt
                    pgrep -P $mypid  >> stoppids_sql_collectors.txt
                done
        fi
}

sql_collect_xevent()
{
        #start any XE collection if defined? XE file should be named pssdiag_xevent_.sql.
        if [[ $COLLECT_EXTENDED_EVENTS == [Yy][eE][sS]  ]]; then
                echo "	Starting SQL Extended Events collection...  "
                /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"pssdiag_xevent.sql" -o"$outputdir/${1}_pssdiag_xevent.out"
                cp -f ./pssdiag_xevent_start.template ./pssdiag_xevent_start.sql
		if [[ "$2" == "host_instance" ]]; then
	                sed -i "s|##XeFileName##|${outputdir}/${1}_pssdiag_xevent.xel|" pssdiag_xevent_start.sql
		else
                        sed -i "s|##XeFileName##|/var/opt/mssql/log/${1}_pssdiag_xevent.xel|" pssdiag_xevent_start.sql
		fi
                /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -i"pssdiag_xevent_start.sql" -o"$outputdir/${1}_pssdiag_xevent_start.out"
        fi
}

# end of all function definitions

# start of main script execution
./check_pre_req.sh
if [[ $? -ne 0 ]] ; then
echo "Prerequisites for collecting all data points not installed... exiting"
exit 1
fi

working_dir="$PWD"
outputdir="$working_dir/output"
pssdiag_log="$outputdir/${HOSTNAME}_pssdiag.log"

if [[ -d "$outputdir" ]]; then
 
  read -n1 -r -p "Output directory {$outputdir}  exists.. Do you want to overwrite (Y/N) ?" diroverwrite

echo ""
  if [[ $diroverwrite = [Yy] ]] ;
  then
    rm -rf $outputdir
#    rmdir --ignore-fail-on-non-empty output
    else
     echo "Please delete the output directory and rerun the collector.."
     exit 1
  fi

fi
# Make sure output directory in working directory exists
mkdir -p $working_dir/output
chmod a+w $working_dir/output
cp pssdiag*.conf $working_dir/output
echo "Working Directory: {$working_dir} " > $pssdiag_log
echo "Output Directory: {$outputdir} " >> $pssdiag_log

# Parameter processing from Config files pssdiag.conf in same directory
# Read config files, if defaults are overwridden there, they will be adhered to
# Config file values are  Key value pairs Example"  COLLECT_CONFIG=YES

CONFIG_FILE="./pssdiag_collector.conf"
echo "Reading configuration values from Config file $CONFIG_FILE"
if [[ -f $CONFIG_FILE ]]; then
. $CONFIG_FILE
fi

# Specify all the defaults here if not specified in config file.
####################################################
COLLECT_CONFIG=${COLLECT_CONFIG:-"YES"}
COLLECT_PERFSTATS=${COLLECT_PERFSTATS:-"YES"}
COLLECT_EXTENDED_EVENTS=${COLLECT_EXTENDED_EVENTS:-"NO"}
COLLECT_SQL_COUNTERS=${COLLECT_SQL_COUNTERS:-"YES"}
COLLECT_SQL_MEM_STATS=${COLLECT_SQL_MEM_STATS:-"NO"}
SQL_COUNTERS_INTERVAL=${SQL_COUNTERS_INTERVAL:-"10"}
COLLECT_OS_COUNTERS=${COLLECT_OS_COUNTERS:-"YES"}
OS_COUNTERS_INTERVAL=${OS_COUNTERS_INTERVAL:=-"10"}
COLLECT_LOGS=${COLLECT_LOGS:-"YES"}
CUSTOM_COLLECTOR=${CUSTOM_COLLECTOR:-"NO"}
COLLECT_HOST=${COLLECT_HOST:-"YES"}
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"NO"}
##############################################################

#collect basic machine configuration
if [[ $COLLECT_CONFIG == "YES" ]] ; then
	./collect_machineconfig.sh
	./collect_container_info.sh
fi

if [[ $COLLECT_OS_COUNTERS == [Yy][eE][sS] ]] ; then
        #Collecting Linux Perf countners
	echo "Starting operating system collectors"
        echo "	Starting io stats collector as a background job..."
        (
        bash ./collect_io_stats.sh $OS_COUNTERS_INTERVAL &
        )
        echo "	Starting cpu stats collector as a background job..."
        (
        bash ./collect_cpu_stats.sh $OS_COUNTERS_INTERVAL &
        )
        echo "	Starting memory collector as a background job..."
        (
        bash ./collect_mem_stats.sh $OS_COUNTERS_INTERVAL &
        )
        echo "	Starting process collector as a background job..."
        (
        bash  ./collect_process_stats.sh $OS_COUNTERS_INTERVAL &
        )
        echo "	Starting network stats  collector as a background job..."
        (
        bash  ./collect_network_stats.sh $OS_COUNTERS_INTERVAL &
        )
        #Collecting Timezone required to process some of the data
        date +%z > $outputdir/${HOSTNAME}_timezone.info &
fi

#this section will connect to sql server instances and collect sql script outputs
if [[ "$COLLECT_HOST" == "YES" ]];then
	#we collect information from base host instance of SQL Server
        echo "collecting sql scripts from host : $HOSTNAME"
	SQL_LISTEN_PORT=$(get_sql_listen_port "host_instance")
	SQL_SERVER_NAME="$HOSTNAME,$SQL_LISTEN_PORT"
	sql_connect "host_instance" "${HOSTNAME}" "${SQL_LISTEN_PORT}"
	sqlconnect=$?
	if [[ $sqlconnect -ne 1 ]]; then
		echo "	Connection to SQL Server instance failed, SQL scripts will not be collected. Only OS scripts will be collected"
	else
		sql_collect_config "${HOSTNAME}"
		sql_collect_perfstats "${HOSTNAME}"
		sql_collect_counters "${HOSTNAME}"
		sql_collect_memstats "${HOSTNAME}"
		sql_collect_custom "${HOSTNAME}"
		sql_collect_xevent "${HOSTNAME}" "host_instance"
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
        	        echo "	Connection to SQL Server instance failed, SQL scripts will not be collected. Only OS scripts will be collected"
	        else
			sql_collect_config "${dockername}"
        	        sql_collect_perfstats "${dockername}"
                	sql_collect_counters "${dockername}"
	                sql_collect_memstats "${dockername}"
        	        sql_collect_custom "${dockername}"
                	sql_collect_xevent "${dockername}" "container_instance"
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
                        	echo "	Connection to SQL Server instance failed, SQL scripts will not be collected. Only OS scripts will be collected"
	                else
				sql_collect_config "${dockername}"
        	                sql_collect_perfstats "${dockername}"
                	        sql_collect_counters "${dockername}"
	                        sql_collect_memstats "${dockername}"
        	                sql_collect_custom "${dockername}"
                	        sql_collect_xevent "${dockername}" "container_instance"
	                fi
                done;
        # we finished processing all the container
        fi
fi

# anchor
# at the end we will always launch an anchor script that we will use to detect if pssdiag is currently running
# if this anchor script is running already we will not allow another pssdiag run to proceed
bash ./pssdiag_anchor.sh &
anchorpid=$!
printf "%s\n" "$anchorpid" >> stoppids_sql_collectors.txt
pgrep -P $anchorpid  >> stoppids_sql_collectors.txt
# anchor

echo -e  "\n \x1B[01;93m Please reproduce the problem now and then stop the data collection... \n"
echo -e  "\x1B[31m Note: Performance collectors started in the background, run stop_collector.sh to stop the background collectors... \n \x1B[0m"

exit 0
