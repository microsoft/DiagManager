#!/bin/bash
outputdir="$PWD/output"


###NOT USED FILE............... the logs are being collected by collect_sql_logs.sh
# get container directive from config file
CONFIG_FILE="./pssdiag_collector.conf"
if [[ -f $CONFIG_FILE ]]; then
. $CONFIG_FILE
fi

# Specify the defaults here if not specified in config file.
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"NO"}

if [[ "$COLLECT_CONTAINER" != "NO" ]]; then
# we need to collect logs from containers
# create a subfolder to collect all logs from containers
mkdir -p $outputdir/log

	if [[ "$COLLECT_CONTAINER" != "ALL" ]]; then
	# we need to process just the specific container
		name=$COLLECT_CONTAINER
		echo "Collecting logs from container : $name"
		dockerid=$(docker ps -q --filter name=$name)
		dockername=$(docker inspect -f "{{.Name}}" $dockerid)
		docker cp $dockerid:/var/opt/mssql/log/. $outputdir/log/$dockername | 2>/dev/null

	else
	# we need to iterate through all containers
		#dockerid_col=$(docker ps | grep 'microsoft/mssql-server-linux' | awk '{ print $1 }')
		dockerid_col=$(docker ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }')
		for dockerid in $dockerid_col;
		do
			dockername=$(docker inspect -f "{{.Name}}" $dockerid)
			echo "Collecting logs from container : $dockername"
			docker cp $dockerid:/var/opt/mssql/log/. $outputdir/log/$dockername | 2>/dev/null
		done;
	fi

fi

