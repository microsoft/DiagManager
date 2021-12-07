#!/bin/bash
outputdir="$PWD/output"

# get container directive from config file
CONFIG_FILE="./pssdiag_collector.conf"
if [[ -f $CONFIG_FILE ]]; then
. $CONFIG_FILE
fi

# Specify the defaults here if not specified in config file.
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"NO"}
COLLECT_HOST_SQL_INSTANCE=${COLLECT_HOST_SQL_INSTANCE:-"NO"}

# detect if docker is installed on the system
if pgrep -x "dockerd" > /dev/null
then
        # we need to iterate through all containers
	echo "collecting information about docker containers"
	sudo docker ps -a > $outputdir/${HOSTNAME}_docker_containers.out
        dockerid_col=$(docker ps | grep 'microsoft/mssql-server-linux' | awk '{ print $1 }')
        for dockerid in $dockerid_col;
        do
	        dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
		#sudo docker inspect $dockerid >> $outputdir/${dockername}_inspect.out
        done;
else
	echo "docker is not installed, so skipping collection"
fi


