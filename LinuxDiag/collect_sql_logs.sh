#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

collect_docker_sql_logs()
{

	dockerid=$1
	dockername=$2

	#Check if we have configuration files. default container deployment with no mounts do not have /var/opt/mssql/mssql.conf so we need to check this upfront. 
	docker_has_mssqlconf=$(docker exec --user root ${dockername} sh -c "(ls /var/opt/mssql/mssql.conf >> /dev/null 2>&1 && echo YES) || echo NO")

	#Collecting errorlog
	logger "Collecting errorlog system_health alwayson_health trc logs : $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	if [[ "${docker_has_mssqlconf}" == "YES" ]]; then
		get_docker_conf_option '/var/opt/mssql/mssql.conf' 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog' $dockername
		SQL_ERRORLOG=$get_docker_conf_option_result
		SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
	else
		SQL_ERRORLOG="/var/opt/mssql/log/errorlog"
		SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
	fi


	if hash bzip2 2>/dev/null; then
		docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* *_health*.xel HkEngineEventFile*.xel log*.trc" | bzip2 > $outputdir/${dockername}_container_instance_sql_logs.bz2
	else
		docker exec $dockerid sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* *_health*.xel HkEngineEventFile*.xel log*.trc" | $outputdir/${dockername}_container_instance_sql_logs.tar
	fi

	#Collecting sqlagents logs
	logger "Collecting sqlagent logs : $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

	if [[ "${docker_has_mssqlconf}" == "YES" ]]; then
		get_docker_conf_option '/var/opt/mssql/mssql.conf' 'sqlagent' 'errorlogfile' '/var/opt/mssql/log/sqlagent' $dockername
		SQL_AGENTLOG=$get_docker_conf_option_result
		SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
	else
		SQL_AGENTLOG="/var/opt/mssql/log/sqlagent"
		SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
	fi
	if hash bzip2 2>/dev/null; then
		docker exec $dockerid sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | bzip2 > $outputdir/${dockername}_container_instance_sqlagent_logs.bz2
		# Collecting sqlagentstartup.log, which is always at /var/opt/mssql/log regardless of filelocation in mssql.conf
		docker exec $dockerid sh -c "cd /var/opt/mssql/log/ && tar -cf - sqlagentstartup.log" | bzip2 >> $outputdir/${dockername}_container_instance_sqlagent_logs.bz2
	else
		docker exec $dockerid sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | cat > $outputdir/${dockername}_container_instance_sqlagent_logs.tar
		# Collecting sqlagentstartup.log, which is always at /var/opt/mssql/log regardless of filelocation in mssql.conf
		docker exec $dockerid sh -c "cd /var/opt/mssql/log/ && tar -cf - sqlagentstartup.log" | cat >> $outputdir/${dockername}_container_instance_sqlagent_logs.tar
	fi

	##Collecting pal logs form container instance
	docker_has_loggerini=$(docker exec --user root ${dockername} sh -c "(ls /var/opt/mssql/logger.ini >> /dev/null 2>&1 && echo YES) || echo NO")

	if [[ "${docker_has_loggerini}" == "YES" ]]; then
		logger "Collecting pal logs from container: $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		get_docker_conf_option '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' 'NA' $dockername
		result=$get_docker_conf_option_result
		if [ "$result" = "NA" ]; then
			get_docker_conf_option '/var/opt/mssql/logger.ini' 'Output.sql' 'filename' 'NA' $dockername
			result=$get_docker_conf_option_result
		fi
		if [ "${result}" != "NA" ]; then
			PAL_LOG="${result}"
			PAL_LOG_DIR=$(dirname $PAL_LOG)
			PAL_LOG=$(basename $PAL_LOG)

			if hash bzip2 2>/dev/null; then
				docker exec $dockerid sh -c "cd ${PAL_LOG_DIR} && tar -cf - ${PAL_LOG}*" | bzip2 > $outputdir/${dockername}_container_instance_pal_logs.bz2
			else
				docker exec $dockerid sh -c "cd ${PAL_LOG_DIR} && tar -cf - ${PAL_LOG}*" | $outputdir/${dockername}_container_instance_pal_logs.tar
			fi
		else
			logger "logger.ini maybe malformed, skipping pal log collection for container : $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		fi
	fi

	#Collect mssql.conf, this one we need to echo out before collection as info about this container
	logger "Collecting mssql.conf from container instance : $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	if [[ "${docker_has_mssqlconf}" == "YES" ]]; then
		docker cp $dockerid:/var/opt/mssql/mssql.conf $outputdir/${dockername}_container_instance_mssql.conf | 2>/dev/null
	else
		logger "Container ${dockername} has no mssql.conf file" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	fi

	
}

######################
# Script is starting #
######################

logger "Starting sql logs collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
NOW=`date +"%m_%d_%Y"`

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
				collect_docker_sql_logs $dockerid $dockername
			else			
				logger "Container not found : $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
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
if [[ "$COLLECT_HOST_SQL_INSTANCE" = [Yy][Ee][Ss] ]]; then
	#Collecting errorlog* system_health*.xel log*.trc
	get_host_instance_status
	#only check if its installed, if its installed then regradlesss if its active or not we need to collect the logs 
	if [ "${is_host_instance_service_installed}" == "YES" ]; then
		if [ -e "/var/opt/mssql/mssql.conf" ]; then
			get_host_conf_option '/var/opt/mssql/mssql.conf' 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog'
			SQL_ERRORLOG=$get_host_conf_option_result
			SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
		else
			SQL_ERRORLOG="/var/opt/mssql/log/errorlog"
			SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
		fi

		if [ -d "$SQL_LOG_DIR" ]; then
			logger "Collecting errorlog system_health alwayson_health trc logs from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
#			sh -c 'tar -cjf "$0/$3_host_instance_sql_logs_$1.tar.bz2" $2/errorlog* $2/system_health*.xel $2/alwayson_health*.xel*.xel $2/log*.trc --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SQL_LOG_DIR" "$HOSTNAME"			
			if hash bzip2 2>/dev/null; then
				current_dir="$PWD"
				sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* *_health*.xel HkEngineEventFile*.xel log*.trc " | bzip2 > $outputdir/${HOSTNAME}_host_instance_sql_logs.bz2
				cd ${current_dir}
			else
				current_dir="$PWD"
				sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* *_health*.xel HkEngineEventFile*.xel log*.trc " | $outputdir/${HOSTNAME}_host_instance_sql_logs.tar
				cd ${current_dir}
			fi
		fi
		
		#Collecting sqlagents logs
		if [ -e "/var/opt/mssql/mssql.conf" ]; then
			get_host_conf_option '/var/opt/mssql/mssql.conf' 'sqlagent' 'errorlogfile' '/var/opt/mssql/log/sqlagent'
			SQL_AGENTLOG=$get_host_conf_option_result
			SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
		else
			SQL_AGENTLOG="/var/opt/mssql/log/sqlagent"
			SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
		fi
		if [ -d "$SQL_AGENTLOG_DIR" ]; then
			logger "Collecting sqlagent logs from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
#			sh -c 'tar -cjf "$0/$3_host_instance_sqlagent_logs_$1.tar.bz2" $2/sqlagent* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SQL_AGENTLOG_DIR" "$HOSTNAME"
			if hash bzip2 2>/dev/null; then
				current_dir="$PWD"
				sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | bzip2 > $outputdir/${HOSTNAME}_host_instance_sqlagent_logs.bz2
				# Collecting sqlagentstartup.log, which is always at /var/opt/mssql/log regardless of filelocation in mssql.conf
				sh -c "cd /var/opt/mssql/log && tar -cf - sqlagentstartup.log" | bzip2 >> $outputdir/${HOSTNAME}_host_instance_sqlagent_logs.bz2
				cd ${current_dir}
			else
				current_dir="$PWD"
				sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | cat > $outputdir/${HOSTNAME}_host_instance_sqlagent_logs.tar
				# Collecting sqlagentstartup.log, which is always at /var/opt/mssql/log regardless of filelocation in mssql.conf
				sh -c "cd /var/opt/mssql/log && tar -cf - sqlagentstartup.log" | cat >> $outputdir/${HOSTNAME}_host_instance_sqlagent_logs.tar
				cd ${current_dir}
			fi
		fi

		#Collecting pal logs 
		if [ -e "/var/opt/mssql/logger.ini" ]; then
			logger "Collecting pal logs from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			get_host_conf_option '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' 'NA'
			result=$get_host_conf_option_result
			if [ "$result" = "NA" ]; then
				#try . instead of :
				get_host_conf_option '/var/opt/mssql/logger.ini' 'Output.sql' 'filename' 'NA'
				result=$get_host_conf_option_result
			fi
			if [ "${result}" != "NA" ]; then
				PAL_LOG="${result}"
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
			else
				logger "logger.ini maybe malformed, skipping pal log collection for host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			fi
		fi
			
		#Getting mssql.conf
		logger "Collecting mssql.conf from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

		if [ -e "/var/opt/mssql/mssql.conf" ]; then
			cp /var/opt/mssql/mssql.conf $outputdir/${HOSTNAME}_host_instance_mssql.conf
		else
			logger "Host instance has no mssql.conf file" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		fi
	fi
fi

#Collect informaiton if we are running inside container
if [[ "$COLLECT_HOST_SQL_INSTANCE" = [Yy][Ee][Ss] ]]; then
	#Collecting errorlog* system_health*.xel log*.trc
	pssdiag_inside_container_get_instance_status
	if [ "${is_instance_inside_container_active}" == "YES" ]; then
		SQL_ERRORLOG="/var/opt/mssql/log/errorlog"
		SQL_LOG_DIR=$(dirname $SQL_ERRORLOG)
		if [ -d "$SQL_LOG_DIR" ]; then
			logger "Collecting errorlog system_health alwayson_health trc logs from instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			if hash bzip2 2>/dev/null; then
				current_dir="$PWD"
				sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* *_health*.xel HkEngineEventFile*.xel log*.trc" | bzip2 > $outputdir/${HOSTNAME}_instance_sql_logs.bz2
				cd ${current_dir}
			else
				current_dir="$PWD"
				sh -c "cd ${SQL_LOG_DIR} && tar -cf - errorlog* *_health*.xel HkEngineEventFile*.xel log*.trc" | $outputdir/${HOSTNAME}_host_instance_sql_logs.tar
				cd ${current_dir}
			fi
		fi
		
		#Collecting sqlagents logs
		SQL_AGENTLOG="/var/opt/mssql/log/sqlagent"
		SQL_AGENTLOG_DIR=$(dirname $SQL_AGENTLOG)
		if [ -d "$SQL_AGENTLOG_DIR" ]; then
			logger "Collecting sqlagent logs from instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			if hash bzip2 2>/dev/null; then
				current_dir="$PWD"
				sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | bzip2 > $outputdir/${HOSTNAME}_instance_sqlagent_logs.bz2
				# Collecting sqlagentstartup.log, which is always at /var/opt/mssql/log regardless of filelocation in mssql.conf
				sh -c "cd /var/opt/mssql/log && tar -cf - sqlagentstartup.log" | bzip2 >> $outputdir/${HOSTNAME}_instance_sqlagent_logs.bz2
				cd ${current_dir}
			else
				current_dir="$PWD"
				sh -c "cd ${SQL_AGENTLOG_DIR} && tar -cf - sqlagent*" | cat > $outputdir/${HOSTNAME}_host_instance_sqlagent_logs.tar
				# Collecting sqlagentstartup.log, which is always at /var/opt/mssql/log regardless of filelocation in mssql.conf
				sh -c "cd /var/opt/mssql/log && tar -cf - sqlagentstartup.log" | cat >> $outputdir/${HOSTNAME}_host_instance_sqlagent_logs.tar
				cd ${current_dir}
			fi
		fi

		#Collecting pal logs 
		if [ -e "/var/opt/mssql/logger.ini" ]; then
			logger "Collecting pal logs from instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			get_host_conf_option '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' 'NA'
			result=$get_host_conf_option_result
			if [ "$result" = "NA" ]; then
				get_host_conf_option '/var/opt/mssql/logger.ini' 'Output.sql' 'filename' 'NA'
				result=$get_host_conf_option_result
			fi
			if [ "${result}" != "NA" ]; then
				PAL_LOG="${result}"
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
			else
				logger "logger.ini maybe malformed, skipping pal log collection for instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			fi
		fi
			
		#Getting mssql.conf
		logger "Collecting mssql.conf from instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

		if [ -e "/var/opt/mssql/mssql.conf" ]; then
			cp /var/opt/mssql/mssql.conf $outputdir/${HOSTNAME}_instance_mssql.conf
		else
			logger "Host instance has no mssql.conf file" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		fi
	fi
fi

exit 0

