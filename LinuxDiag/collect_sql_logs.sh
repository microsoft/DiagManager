#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

collect_docker_sql_logs()
{

dockerid=$1
dockername=$2


#Collectin errorlog* system_health*.xel log*.trc

#Check if we have configuration files. default container deployment with no mounts do not have /var/opt/mssql/mssql.conf so we need to check this upfront. 
docker_has_mssqlconf=$(docker exec --user root ${dockername} sh -c "(ls /var/opt/mssql/mssql.conf >> /dev/null 2>&1 && echo YES) || echo NO")

#Collecting errorlog
echo -e "$(date -u +"%T %D") Collecting errorlog system_health trc logs : $dockername..." | tee -a $pssdiag_log
if [[ "${docker_has_mssqlconf}" == "YES" ]]; then
	SQL_ERRORLOG=$(get_docker_conf_optionx '/var/opt/mssql/mssql.conf' 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog' $dockername)
	SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
else
	SQL_ERRORLOG="/var/opt/mssql/log/errorlog"
	SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
fi

if hash bzip2 2>/dev/null; then
	docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* system_health*.xel log*.trc" | bzip2 > $outputdir/${dockername}_container_instance_sql_logs.bz2
else
	docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* system_health*.xel log*.trc" | $outputdir/${dockername}_container_instance_sql_logs.tar
fi

#Collecting sqlagents logs
echo -e "$(date -u +"%T %D") Collecting sqlagent logs from container : $dockername..." | tee -a $pssdiag_log

if [[ "${docker_has_mssqlconf}" == "YES" ]]; then
	SQL_AGENTLOG=$(get_docker_conf_optionx '/var/opt/mssql/mssql.conf' 'sqlagent' 'errorlogfile' '/var/opt/mssql/log/sqlagent' $dockername)
	SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
else
	SQL_AGENTLOG="/var/opt/mssql/log/sqlagent"
	SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
fi
if hash bzip2 2>/dev/null; then
	docker exec $dockerid sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | bzip2 > $outputdir/${dockername}_container_instance_sqlagent_logs.bz2
else
	docker exec $dockerid sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | $outputdir/${dockername}_container_instance_sqlagent_logs.tar
fi

##Collecting pal logs form container instance
docker_has_loggerini=$(docker exec --user root ${dockername} sh -c "(ls /var/opt/mssql/logger.ini >> /dev/null 2>&1 && echo YES) || echo NO")

if [[ "${docker_has_loggerini}" == "YES" ]]; then
	echo -e "$(date -u +"%T %D") Collecting pal logs from container : $dockername..." | tee -a $pssdiag_log
	PAL_LOG=$(get_docker_conf_optionx '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' '/var/opt/mssql/log/security.log' $dockername)
	PAL_LOG_DIR=$(dirname $PAL_LOG)
	PAL_LOG=$(basename $PAL_LOG)

	if hash bzip2 2>/dev/null; then
		docker exec $dockerid sh -c "cd ${PAL_LOG_DIR} && tar -cf - ${PAL_LOG}*" | bzip2 > $outputdir/${dockername}_container_instance_pal_logs.bz2
	else
		docker exec $dockerid sh -c "cd ${PAL_LOG_DIR} && tar -cf - ${PAL_LOG}*" | $outputdir/${dockername}_container_instance_pal_logs.tar
	fi
else
	echo -e "$(date -u +"%T %D") Container ${dockername} has no pal logs : $dockername... " | tee -a $pssdiag_log
fi

#Collect mssql.conf, this one we need to echo out before collection as info about this container
echo -e "$(date -u +"%T %D") Collecting mssql.conf from container instance : $dockername..." | tee -a $pssdiag_log
if [[ "${docker_has_mssqlconf}" == "YES" ]]; then
	docker cp $dockerid:/var/opt/mssql/mssql.conf $outputdir/${dockername}_container_instance_mssql.conf | 2>/dev/null
else
	echo -e "$(date -u +"%T %D") Container ${dockername} has no mssql.conf file..." | tee -a $pssdiag_log
fi
}

#Script is starting
echo -e "$(date -u +"%T %D") Starting sql logs collection..." | tee -a $pssdiag_log

if [[ -d "$1" ]] ; then
	outputdir="$1"
else
   working_dir="$PWD"
   # Make sure log directory in working directory exists
    mkdir -p $working_dir/output

   # Define files and locations
   outputdir="$working_dir/output"
fi

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
	get_container_instance_status
	if [ "${is_container_runtime_service_active}" == "YES" ]; then
		if [[ "$COLLECT_CONTAINER" != "ALL" ]]; then
		# we need to process just the specific container
			dockername=$COLLECT_CONTAINER
			dockerid=$(docker ps -q --filter name=$dockername)
			if [ $dockerid ]; then
				collect_docker_sql_logs $dockerid $dockername
			else			
				echo -e "$(date -u +"%T %D") Container not found : $dockername ..." | tee -a $pssdiag_log
			fi
		else
			# we need to iterate through all containers
			#dockerid_col=$(docker ps | grep 'mcr.microsoft.com/mssql/server' | awk '{ print $1 }')
			dockerid_col=$(docker ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }')
			for dockerid in $dockerid_col;
			do
				dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
				collect_docker_sql_logs $dockerid $dockername		
			done;
		fi
	fi
fi


#Collect from host instance
if [[ "$COLLECT_HOST_SQL_INSTANCE" = "YES" ]]; then
	#Collecting errorlog* system_health*.xel log*.trc
	get_host_instance_status
	#only check if its installed, if its installed then regradlesss if its active or note we need to collect the logs 
	if [ "${is_host_instance_service_installed}" == "YES" ]; then
		if [ -e "/var/opt/mssql/mssql.conf" ]; then
			SQL_ERRORLOG=$(get_conf_optionx '/var/opt/mssql/mssql.conf' 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog')
			SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
		else
			SQL_ERRORLOG="/var/opt/mssql/log/errorlog"
			SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
		fi

		if [ -d "$SQL_LOG_DIR" ]; then
			echo -e "$(date -u +"%T %D") Collecting errorlog system_health trc from host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
			if hash bzip2 2>/dev/null; then
				current_dir="$PWD"
				sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* system_health*.xel log*.trc" | bzip2 > $outputdir/${HOSTNAME}_host_instance_sql_logs.bz2
				cd ${current_dir}
			else
				current_dir="$PWD"
				sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* system_health*.xel log*.trc" | $outputdir/${HOSTNAME}_host_instance_sql_logs.tar
				cd ${current_dir}
			fi
		fi
		
		#Collecting sqlagents logs
		if [ -e "/var/opt/mssql/mssql.conf" ]; then
			SQL_AGENTLOG=$(get_conf_optionx '/var/opt/mssql/mssql.conf' 'sqlagent' 'errorlogfile' '/var/opt/mssql/log/sqlagent')
			SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
		else
			SQL_AGENTLOG="/var/opt/mssql/log/sqlagent"
			SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
		fi
		if [ -d "$SQL_AGENTLOG_DIR" ]; then
			echo -e "$(date -u +"%T %D") Collecting sqlagent logs from from host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
			if hash bzip2 2>/dev/null; then
				current_dir="$PWD"
				sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | bzip2 > $outputdir/${HOSTNAME}_host_instance_sqlagnet_logs.bz2
				cd ${current_dir}
			else
				current_dir="$PWD"
				sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | $outputdir/${HOSTNAME}_host_instance_sqlagent_logs.tar
				cd ${current_dir}
			fi
		fi

		#Collecting pal logs 
		if [ -e "/var/opt/mssql/logger.ini" ]; then
			echo -e "$(date -u +"%T %D") Collecting pal logs from host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
			PAL_LOG=$(get_conf_optionx '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' '/var/opt/mssql/log/security.log' | cut -f 1 -d '.')
			PAL_LOG_DIR=$(dirname $PAL_LOG)
			PAL_LOG=$(basename $PAL_LOG)
			if [ -d "$PAL_LOG_DIR" ]; then
				if hash bzip2 2>/dev/null; then
					current_dir="$PWD"
					sh -c "cd ${PAL_LOG_DIR} && tar -cf - ${PAL_LOG}*" | bzip2 > $outputdir/${HOSTNAME}_host_instance_pal_logs.bz2
					cd ${current_dir}
				else
					current_dir="$PWD"
					sh -c "cd ${PAL_LOG_DIR} && tar -cf - ${PAL_LOG}*" | $outputdir/${HOSTNAME}_host_instance_pal_logs.tar
					cd ${current_dir}
				fi
			fi
		fi
			
		#Getting mssql.conf
		echo -e "$(date -u +"%T %D") Collecting mssql.conf from host instance : ${HOSTNAME}... " | tee -a $pssdiag_log

		if [ -e "/var/opt/mssql/mssql.conf" ]; then
			cp /var/opt/mssql/mssql.conf $outputdir/${HOSTNAME}_host_instance_mssql.conf
		else
			echo -e "$(date -u +"%T %D") Host instance has no mssql.conf file..." | tee -a $pssdiag_log
		fi
	fi
fi


#Collect informaiton if we are running inside container
if [[ "$COLLECT_HOST_SQL_INSTANCE" = "YES" ]]; then
	#Collecting errorlog* system_health*.xel log*.trc
	pssdiag_inside_container_get_instance_status
	if [ "${is_instance_inside_container_active}" == "YES" ]; then
		SQL_ERRORLOG="/var/opt/mssql/log/errorlog"
		SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
		if [ -d "$SQL_LOG_DIR" ]; then
			echo -e "$(date -u +"%T %D") Collecting errorlog system_health trc from instance : ${HOSTNAME}..." | tee -a $pssdiag_log
			if hash bzip2 2>/dev/null; then
				current_dir="$PWD"
				sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* system_health*.xel log*.trc sqlagent*" | bzip2 > $outputdir/${HOSTNAME}_instance_sql_logs.bz2
				cd ${current_dir}
			else
				current_dir="$PWD"
				sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* system_health*.xel log*.trc sqlagent*" | $outputdir/${HOSTNAME}_host_instance_sql_logs.tar
				cd ${current_dir}
			fi
		fi
		
		#Collecting sqlagents logs
		SQL_AGENTLOG="/var/opt/mssql/log/sqlagent"
		SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
		if [ -d "$SQL_AGENTLOG_DIR" ]; then
			echo -e "$(date -u +"%T %D") Collecting sqlagent logs from from instance : ${HOSTNAME}..." | tee -a $pssdiag_log
			if hash bzip2 2>/dev/null; then
				current_dir="$PWD"
				sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | bzip2 > $outputdir/${HOSTNAME}_instance_sqlagnet_logs.bz2
				cd ${current_dir}
			else
				current_dir="$PWD"
				sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | $outputdir/${HOSTNAME}_host_instance_sqlagent_logs.tar
				cd ${current_dir}
			fi
		fi

		#Collecting pal logs 
		if [ -e "/var/opt/mssql/logger.ini" ]; then
			echo -e "$(date -u +"%T %D") Collecting pal logs from instance : ${HOSTNAME}..." | tee -a $pssdiag_log
			PAL_LOG=$(get_conf_optionx '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' '/var/opt/mssql/log/security.log' | cut -f 1 -d '.')
			PAL_LOG_DIR=$(dirname $PAL_LOG)
			PAL_LOG=$(basename $PAL_LOG)
			if [ -d "$PAL_LOG_DIR" ]; then
				if hash bzip2 2>/dev/null; then
					current_dir="$PWD"
					sh -c "cd ${PAL_LOG_DIR} && tar -cf - ${PAL_LOG}*" | bzip2 > $outputdir/${HOSTNAME}_instance_pal_logs.bz2
					cd ${current_dir}
				else
					current_dir="$PWD"
					sh -c "cd ${PAL_LOG_DIR} && tar -cf - ${PAL_LOG}*" | $outputdir/${HOSTNAME}_host_instance_pal_logs.tar
					cd ${current_dir}
				fi
			fi
		fi
			
		#Getting mssql.conf
		echo -e "$(date -u +"%T %D") Collecting mssql.conf from instance : ${HOSTNAME}... " | tee -a $pssdiag_log

		if [ -e "/var/opt/mssql/mssql.conf" ]; then
			cp /var/opt/mssql/mssql.conf $outputdir/${HOSTNAME}_instance_mssql.conf
		else
			echo -e "$(date -u +"%T %D") instance has no mssql.conf file..." | tee -a $pssdiag_log
		fi
	fi
fi



