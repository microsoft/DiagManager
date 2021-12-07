#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh
outputdir="$PWD/output"
SQL_LOG_DIR="/var/opt/mssql/log"

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
		name=$COLLECT_CONTAINER
		echo "collecting sql instance logs from container : $name"
		dockerid=$(docker ps -q --filter name=$name)
		dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
#		SQL_LOG_DIR=$(get_sql_log_directory "container_instance" "2" $dockerid)
		if hash bzip2 2>/dev/null; then
			docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | bzip2 > $outputdir/${dockername}_sql_logs.bz2
		else
			docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | $outputdir/${dockername}_sql_logs.tar
		fi
		docker cp $dockerid:/var/opt/mssql/mssql.conf $outputdir/${dockername}_mssql.conf
	else
	# we need to iterate through all containers
		dockerid_col=$(docker ps | grep 'microsoft/mssql-server-linux' | awk '{ print $1 }')
		for dockerid in $dockerid_col;
		do
			dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
			echo "collecting sql instance logs from container : $dockername"
#			SQL_LOG_DIR=$(get_sql_log_directory "container_instance" "2" $dockerid)
			if hash bzip2 2>/dev/null; then
				docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | bzip2 > $outputdir/${dockername}_sql_logs.bz2
			else
				docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | $outputdir/${dockername}_sql_logs.tar
			fi
		docker cp $dockerid:/var/opt/mssql/mssql.conf $outputdir/${dockername}_mssql.conf
		done;
	fi
fi

if [[ "$COLLECT_HOST_SQL_INSTANCE" = "YES" ]]; then
# we need to collect logs from host machine
	echo "collecting sql instance logs from host instance"
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
	fi
fi

