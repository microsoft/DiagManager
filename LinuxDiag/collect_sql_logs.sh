#!/bin/bash

# include helper functions


source ./pssdiag_support_functions.sh


collect_docker_sql_logs()
{

dockerid=$1
dockername=$2

echo "collecting sql instance logs from container : $dockername" | tee -a $pssdiag_log

#SQL_LOG_DIR=$(get_sql_log_directory "container_instance" "2" $dockerid)
SQL_ERRORLOG=$(get_docker_conf_option $dockerid 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog')
SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)

if hash bzip2 2>/dev/null; then
	docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | bzip2 > $outputdir/${dockername}_sql_logs.bz2
else
	docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | $outputdir/${dockername}_sql_logs.tar
fi

if ! docker cp $dockerid:/var/opt/mssql/mssql.conf $outputdir/${dockername}_mssql.conf;  then
	touch $outputdir/${dockername}_mssql.conf
fi

}

# get container directive from config file
CONFIG_FILE="./pssdiag_collector.conf"
if [[ -f $CONFIG_FILE ]]; then
. $CONFIG_FILE
fi

# Specify the defaults here if not specified in config file.
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"NO"}
COLLECT_HOST_SQL_INSTANCE=${COLLECT_HOST_SQL_INSTANCE:-"NO"}

if [[ "$COLLECT_CONTAINER" != "NO" ]]; then
# we need to collect logs from containers

	if [[ "$COLLECT_CONTAINER" != "ALL" ]]; then
	# we need to process just the specific container
		
		dockername=$COLLECT_CONTAINER

		dockerid=$(docker ps -q --filter name=$dockername)

		if [ $dockerid ]; then
			collect_docker_sql_logs $dockerid $dockername
		else			
			echo "Container not found : $dockername" | tee -a $pssdiag_log
		fi

	else

		echo "Collect logs for ALL containers" | tee -a $pssdiag_log
		# we need to iterate through all containers
		dockerid_col=$(docker ps | grep 'mcr.microsoft.com/mssql/server' | awk '{ print $1 }')
		for dockerid in $dockerid_col;
		do
			dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)

			collect_docker_sql_logs $dockerid $dockername
		
		done;
	fi
fi

if [[ "$COLLECT_HOST_SQL_INSTANCE" = "YES" ]]; then
# we need to collect logs from host machine
	echo "collecting sql instance logs from host instance" | tee -a $pssdiag_log
	#TODO: TEST
	SQL_ERRORLOG=$(get_conf_option 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog')
	SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
#	SQL_LOG_DIR=$(get_sql_log_directory "host_instance")
	if [ -d "$SQL_LOG_DIR" ]; then
		if hash bzip2 2>/dev/null; then
			sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | bzip2 > $outputdir/${HOSTNAME}_sql_logs.bz2
		else
			sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | $outputdir/${HOSTNAME}_sql_logs.tar
		fi
	fi
	if [ -e "/var/opt/mssql/mssql.conf" ]; then
		cp /var/opt/mssql/mssql.conf $outputdir/${HOSTNAME}_mssql.conf
	else
		touch $outputdir/${HOSTNAME}_mssql.conf
	fi
fi

