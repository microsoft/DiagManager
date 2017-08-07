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
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"ALL"}
COLLECT_HOST=${COLLECT_HOST:-"YES"}

if [[ "$COLLECT_CONTAINER" != "NO" ]]; then
# we need to collect logs from containers

	if [[ "$COLLECT_CONTAINER" != "ALL" ]]; then
	# we need to process just the specific container
		name=$COLLECT_CONTAINER
		echo "collecting sql logs from container : $name"
		dockerid=$(docker ps -q --filter name=$name)
		dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
#		SQL_LOG_DIR=$(get_sql_log_directory "container_instance" "2" $dockerid)
		docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | gzip > $outputdir/${dockername}_sql_logs.tgz
		docker cp $dockerid:/var/opt/mssql/mssql.conf $outputdir/${dockername}_mssql.conf
	else
	# we need to iterate through all containers
		dockerid_col=$(docker ps -q --filter ancestor=microsoft/mssql-server-linux)
		for dockerid in $dockerid_col;
		do
			dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
			echo "collecting sql logs from container : $dockername"
#			SQL_LOG_DIR=$(get_sql_log_directory "container_instance" "2" $dockerid)
			docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | gzip > $outputdir/${dockername}_sql_logs.tgz
		docker cp $dockerid:/var/opt/mssql/mssql.conf $outputdir/${dockername}_mssql.conf
		done;
	fi
fi

if [[ "$COLLECT_HOST" = "YES" ]]; then
# we need to collect logs from host machine
	echo "collecting sql logs from host instance"
#	SQL_LOG_DIR=$(get_sql_log_directory "host_instance")
	sudo sh -c "cd ${SQL_LOG_DIR} && tar cf - errorlog* system_health*.xel log*.trc" | gzip > $outputdir/${HOSTNAME}_sql_logs.tgz
	sudo cp /var/opt/mssql/mssql.conf $outputdir/${HOSTNAME}_mssql.conf
fi

