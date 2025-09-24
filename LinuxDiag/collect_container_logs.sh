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

if [ $COLLECT_CONTAINER == [Nn][Oo] ] ; then
    exit 0
fi

if [[ "$COLLECT_CONTAINER" != [Nn][Oo] ]]; then
# we need to collect logs from containers
# create a subfolder to collect all logs from containers
mkdir -p $outputdir/log
if [ "$EUID" -eq 0 ]; then
  group=$(id -gn "$SUDO_USER")
  chown "$SUDO_USER:$group" "$outputdir" -R
else
	chown $(id -u):$(id -g) "$outputdir" -R
fi

	if [[ "$COLLECT_CONTAINER" != [Aa][Ll][Ll] ]]; then
	# we need to process just the specific container
		name=$COLLECT_CONTAINER
		logger "Collecting logs from container : $name" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
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
			logger "Collecting logs from container : $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			docker cp $dockerid:/var/opt/mssql/log/. $outputdir/log/$dockername | 2>/dev/null
		done;
	fi

fi

exit 0