#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

collect_docker_dumps()
{

dockerid=$1
dockername=$2

logger "collecting dumps from container : $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

docker_has_mssqlconf=$(docker exec --user root ${dockername} sh -c "(ls /var/opt/mssql/mssql.conf >> /dev/null 2>&1 && echo YES) || echo NO")
if [[ "${docker_has_mssqlconf}" == "YES" ]]; then
        get_docker_conf_option '/var/opt/mssql/mssql.conf' 'filelocation' 'defaultdumpdir' '/var/opt/mssql/log'  $dockername
		SQL_DUMP_DIR=$get_docker_conf_option_result
else
        SQL_DUMP_DIR="/var/opt/mssql/log"
fi
docker exec $dockerid sh -c "cd ${SQL_DUMP_DIR} && tar -cf /tmp/sql_dumps.tar SQLDump*.* *core.sqlservr.* SQLDUMPER* 2>/dev/null" 
docker cp $dockerid:/tmp/sql_dumps.tar ${outputdir}/${dockername}_container_instance_sql_dumps.tar | 2>/dev/null
docker exec $dockerid sh -c "rm -f /tmp/sql_dumps.tar"
}

#Starting the script
logger "Starting sql dumps collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

if [[ -d "$1" ]] ; then
	outputdir="$1"
else
   working_dir="$PWD"
   # Make sure log directory in working directory exists
    mkdir -p $working_dir/output

   # Define files and locations
   outputdir="$working_dir/output"
	if [ "$EUID" -eq 0 ]; then
	ORIGINAL_USERNAME=$(logname)
	ORIGINAL_GROUP=$(id -gn "$ORIGINAL_USERNAME")
	chown "$ORIGINAL_USERNAME:$ORIGINAL_GROUP" "$outputdir" -R
	else
		chown $(id -u):$(id -g) "$outputdir" -R
	fi
fi

# get container directive from config file
CONFIG_FILE="./pssdiag_collector.conf"
if [[ -f $CONFIG_FILE ]]; then
. $CONFIG_FILE
fi

# Specify the defaults here if not specified in config file.
COLLECT_CONTAINER=${COLLECT_CONTAINER:-"NO"}
COLLECT_HOST_SQL_INSTANCE=${COLLECT_HOST_SQL_INSTANCE:-"NO"}

if [[ "$COLLECT_CONTAINER" != [Nn][Oo] ]]; then
# we need to collect logs from containers
	get_container_instance_status
	if [ "${is_container_runtime_service_active}" == "YES" ]; then
		if [[ "$COLLECT_CONTAINER" != [Aa][Ll][Ll] ]]; then
		# we need to process just the specific container
			
			dockername=$COLLECT_CONTAINER
			dockerid=$(docker ps -q --filter name=$dockername)

			if [ $dockerid ]; then
				collect_docker_dumps $dockerid $dockername
			else			
				logger "Container not found : $dockername..." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			fi
		else
			# we need to iterate through all containers
			#dockerid_col=$(docker ps | grep 'mcr.microsoft.com/mssql/server' | awk '{ print $1 }')
			dockerid_col=$(docker ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }')
			for dockerid in $dockerid_col;
			do
				dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
				collect_docker_dumps $dockerid $dockername		
			done;
		fi
	fi
fi
if [[ "$COLLECT_HOST_SQL_INSTANCE" = [Yy][Ee][Ss] ]]; then
	# we need to collect dumps from host instance
	get_host_instance_status
	#only check if its installed, if its installed then regradlesss if its active or note we need to collect the logs 
	if [ "${is_host_instance_service_installed}" == "YES" ]; then
		if [ -e "/var/opt/mssql/mssql.conf" ]; then
			#check if we have mssql.keytab file configured for host instance, the get_host_conf_option and store in var get_host_conf_option_result
			get_host_conf_option '/var/opt/mssql/mssql.conf' 'filelocation' 'defaultdumpdir' '/var/opt/mssql/log'
			SQL_DUMP_DIR=$get_host_conf_option_result
		else
			SQL_DUMP_DIR="/var/opt/mssql/log"
		fi
		if [ -d "$SQL_DUMP_DIR" ]; then
			logger "Collecting dumps for host instance ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			sh -c "cd ${SQL_DUMP_DIR} && tar -cf ${outputdir}/${HOSTNAME}_host_instance_sql_dumps.tar SQLDump*.* *core.sqlservr.* SQLDUMPER* 2>/dev/null"
		fi
	fi
fi

#Collect informaiton if we are running inside container
if [[ "$COLLECT_HOST_SQL_INSTANCE" = [Yy][Ee][Ss] ]]; then
    #Collect dumps if we are running inside container
	pssdiag_inside_container_get_instance_status
	if [ "${is_instance_inside_container_active}" == "YES" ]; then
		SQL_DUMP_DIR="/var/opt/mssql/log"
		if [ -d "$SQL_DUMP_DIR" ]; then
			logger "Collecting dumps for instance ${HOSTNAME} inside container" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			sh -c "cd ${SQL_DUMP_DIR} && tar -cf ${outputdir}/${HOSTNAME}_instance_sql_dumps.tar SQLDump*.* *core.sqlservr.* SQLDUMPER* 2>/dev/null"
		fi
	fi
fi

exit 0