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

if [[ "$COLLECT_CONTAINER" != "NO" ]]; then
# we need to collect dumps from containers

# we need to change this and figure out for each container as mssql-conf can technically change this for the container.
dumplocation="/var/opt/mssql/log"

        if [[ "$COLLECT_CONTAINER" != "ALL" ]]; then
        # we need to process just the specific container
                name=$COLLECT_CONTAINER
                echo "collecting dumps from container : $name"
                dockerid=$(docker ps -q --filter name=$name)
                dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
                docker exec $dockerid sh -c "cd ${dumplocation} && tar cf /tmp/sql_dumps.tar SQLDump*.* core.sqlservr.* " 
		docker cp $dockerid:/tmp/sql_dumps.tar ${outputdir}/${dockername}_sql_dumps.tar
		docker exec $dockerid sh -c "rm -f /tmp/sql_dumps.tar"
        else
        # we need to iterate through all containers
                dockerid_col=$(docker ps | grep 'microsoft/mssql-server-linux' | awk '{ print $1 }')
                for dockerid in $dockerid_col;
                do
                        dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
                        echo "collecting dumps from container : $dockername"
                        docker exec $dockerid sh -c "cd ${dumplocation} && tar cf /tmp/sql_dumps.tar SQLDump*.* core.sqlservr.* "
			docker cp $dockerid:/tmp/sql_dumps.tar ${outputdir}/${dockername}_sql_dumps.tar
			docker exec $dockerid sh -c "rm -f /tmp/sql_dumps.tar"
                done;
        fi
fi

if [[ "$COLLECT_HOST_SQL_INSTANCE" = "YES" ]]; then
# we need to collect dumps from host instance
	dumplocation=`cat /var/opt/mssql/mssql.conf | grep "filelocation.defaultdumpdir" | awk -F' = ' '{ print $2 }'`
	if [ -z $dumplocation ]
	then
	  dumplocation="/var/opt/mssql/log"
	fi


	sudo sh -c "cd ${dumplocation} && tar -cf ${outputdir}/${HOSTNAME}_sql_dumps.tar SQLDump*.* core.sqlservr.* "
fi








