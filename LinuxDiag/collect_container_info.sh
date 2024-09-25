#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

if [[ -d "$1" ]] ; then
	outputdir="$1"
else
   working_dir="$PWD"
   # Make sure log directory in working directory exists
    mkdir -p $working_dir/output

   # Define files and locations
   outputdir="$working_dir/output"
fi

pssdiag_log="$outputdir/pssdiag.log"

# get container directive from config file
CONFIG_FILE="./pssdiag_collector.conf"
if [[ -f $CONFIG_FILE ]]; then
. $CONFIG_FILE
fi

# Specify the defaults here if not specified in config file.
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"NO"}
COLLECT_HOST_SQL_INSTANCE=${COLLECT_HOST_SQL_INSTANCE:-"NO"}

echo -e "$(date -u +"%T %D") Starting containers log collection..." | tee -a $pssdiag_log


# detect if docker is installed on the system
get_container_instance_status
if [ "${is_container_runtime_service_active}" == "YES" ]; then
        # we need to iterate through all containers
	echo -e "$(date -u +"%T %D") Collecting information about docker containers..." | tee -a $pssdiag_log
	
        echo "=======docker ps=======" >> $outputdir/${HOSTNAME}_os_docker_info
        docker ps --all --no-trunc >> $outputdir/${HOSTNAME}_os_docker_info
        echo "" >> $outputdir/${HOSTNAME}_os_docker_info

        echo "=======docker stats=======" >> $outputdir/${HOSTNAME}_os_docker_info
        sudo docker stats --all --no-trunc --no-stream >> $outputdir/${HOSTNAME}_os_docker_info
        echo "" >> $outputdir/${HOSTNAME}_os_docker_info

        echo "=======docker info=======" >> $outputdir/${HOSTNAME}_os_docker_info
        docker info >> $outputdir/${HOSTNAME}_os_docker_info
        echo "" >> $outputdir/${HOSTNAME}_os_docker_info

        echo "=======docker version=======" >> $outputdir/${HOSTNAME}_os_docker_info
        docker version >> $outputdir/${HOSTNAME}_os_docker_info
        echo "" >> $outputdir/${HOSTNAME}_os_docker_info

        dockerid_col=$(docker ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }')
        for dockerid in $dockerid_col;
        do
        	dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
                echo -e "$(date -u +"%T %D") Collecting docker logs for container instance $dockername: ..." | tee -a $pssdiag_log
		docker logs $dockerid >> $outputdir/${dockername}_container_instance_docker_logs.out
        done;
fi

#if podman is being used with docker engine, collect some basic info
if [[ ${is_podman_sql_containers} = "YES" ]]; then
	echo -e "$(date -u +"%T %D") There are podman container instances with no docker service installed, sql logs will not be collected from these containers..." | tee -a $pssdiag_log
	echo -e "$(date -u +"%T %D") Collecting information about podman containers..." | tee -a $pssdiag_log
	
        echo "=======podman ps=======" >> $outputdir/${HOSTNAME}_os_podman_info
        podman ps --all --no-trunc >> $outputdir/${HOSTNAME}_os_podman_info
        echo "" >> $outputdir/${HOSTNAME}_os_podman_info

        echo "=======podman stats=======" >> $outputdir/${HOSTNAME}_os_podman_info
        podman stats --all --no-trunc --no-stream >> $outputdir/${HOSTNAME}_os_podman_info
        echo "" >> $outputdir/${HOSTNAME}_os_podman_info

        echo "=======podman info=======" >> $outputdir/${HOSTNAME}_os_podman_info
        podman info >> $outputdir/${HOSTNAME}_os_podman_info
        echo "" >> $outputdir/${HOSTNAME}_os_podman_info

        echo "=======podman version=======" >> $outputdir/${HOSTNAME}_os_podman_info
        podman version >> $outputdir/${HOSTNAME}_os_podman_info
        echo "" >> $outputdir/${HOSTNAME}_os_podman_info

        podman_col=$(podman ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }')
        for podmanid in $podman_col;
        do
        	podmanname=$(podman inspect -f "{{.Name}}" $podmanid | tail -c +1)
                echo -e "$(date -u +"%T %D") Collecting docker logs for container instance $podmanname: ..." | tee -a $pssdiag_log
		podman logs $podmanid >> $outputdir/${podmanname}_container_instance_podman_logs.out
        done;
fi
