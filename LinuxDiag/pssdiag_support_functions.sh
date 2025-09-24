#!/bin/bash

script_version="20251001"
MSSQL_CONF="/var/opt/mssql/mssql.conf"
outputdir="$PWD/output"
#SQL_LOG_DIR=${SQL_LOG_DIR:-"/var/opt/mssql/log"}
pssdiag_log="$outputdir/pssdiag.log"

# Arguments:
#   1. Title
#   2. Command
#
function capture_system_info_command()
{
    title=$1
    command=$2

    echo "=== $title ===" >> $infolog_filename
    eval "$2 2>&1" >> $infolog_filename
    echo "" >> $infolog_filename
}

find_sqlcmd() 
{
	SQLCMD=""
	# Try known sqlcmd paths in order
	if [ -x /opt/mssql-tools/bin/sqlcmd ]; then
		SQLCMD="/opt/mssql-tools/bin/sqlcmd"
	elif [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
		SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
	else
		SQLCMD=""
	fi
}

get_sql_listen_port()
{
CONFIG_NAME="tcpport"
DEFAULT_VALUE="1433"

if [[ "$1" == "host_instance" ]]; then
	FILE_EXISTS=$(sh -c "test -f ${MSSQL_CONF} && echo 'exists' || echo 'not exists'")
	if [[ "${FILE_EXISTS}" == "exists" ]]; then
        	tcpport=`cat ${MSSQL_CONF} | grep -i -w ${CONFIG_NAME} | sed 's/ *= */=/g' | awk -F '=' '{ print $2}'`
        	if [[ ${tcpport} != "" ]] ; then
                	echo "${tcpport}"
        	else
                	echo "${DEFAULT_VALUE}"
        	fi
	else
		echo "${DEFAULT_VALUE}"
	fi
fi

if [[ "$1" == "container_instance" ]]; then
	FILE_EXISTS=$(docker exec ${3} sh -c "test -f ${MSSQL_CONF} && echo 'exists' || echo 'not exists'")
	if [[ "${FILE_EXISTS}" == "exists" ]]; then
		tcpportline=$(docker exec ${3} sh -c "cat ${MSSQL_CONF} | grep -i -w ${CONFIG_NAME}")
		tcpport=`echo ${tcpportline} | sed 's/ *= */=/g' | awk -F '=' '{ print $2}'`
        	if [[ ${tcpport} != "" ]] ; then
                	echo "${tcpport}"
        	else
                	echo "${DEFAULT_VALUE}"
        	fi
	else
		echo "${DEFAULT_VALUE}"
	fi
fi
}

get_docker_mapped_port()
{
               
   dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
   #echo "collecting docker mapped port from sql container instance : $dockername"
   SQL_LISTEN_PORT=$(get_sql_listen_port "container_instance" "2" $dockerid)
   #dynamically build?
   inspectcmd="docker inspect --format='{{(index (index .HostConfig.PortBindings \""
   inspectcmd+=$SQL_LISTEN_PORT
   inspectcmd+="/tcp\") 0).HostPort}}' $dockerid"
   dockerport=`eval $inspectcmd`
   # echo "${dockerport}"
}

#Checking host instance status
get_host_instance_status() 
{
    is_host_instance_service_installed="NO"
    is_host_instance_service_enabled="NO"
    is_host_instance_service_active="NO"
    is_host_instance_process_running="NO"

    # Check if system uses systemd
    if [[ "$(readlink /sbin/init)" == *systemd* ]]; then
        if systemctl list-units --all | grep -q mssql-server.service; then
            is_host_instance_service_installed="YES"

            if systemctl -q is-enabled mssql-server; then
                is_host_instance_service_enabled="YES"
            fi

            if systemctl -q is-active mssql-server; then
                is_host_instance_service_active="YES"
            fi

			if pgrep -f "/opt/mssql/bin/sqlservr" >/dev/null 2>&1; then
				is_host_instance_process_running="YES"
			fi
        fi
    fi
}


#Checking containers status, including podman
get_container_instance_status()
{
	is_container_runtime_service_installed="NO"
	is_container_runtime_service_enabled="NO"
	is_container_runtime_service_active="NO"
	is_docker_sql_containers="NO"
	is_podman_sql_containers="NO"
	is_podman_sql_containers_no_docker_runtime="NO"

  # Check if system uses systemd
    if [[ "$(readlink /sbin/init)" == *systemd* ]]; then
        if systemctl list-units --type=service --state=active | grep -q docker; then
            is_container_runtime_service_installed="YES"

            if systemctl -q is-enabled docker &>/dev/null; then
                is_container_runtime_service_enabled="YES"
            fi

            if systemctl -q is-active docker &>/dev/null; then
                is_container_runtime_service_active="YES"
            fi
        fi
    fi

    # Check for running sql containers using docker 
    if command -v docker &>/dev/null; then
        docker_sql_count=$(docker ps --no-trunc | grep -c '/opt/mssql/bin/sqlservr')
        if (( docker_sql_count > 0 )); then
            is_docker_sql_containers="YES"
        fi
    fi

    # Check for running sql containers using podman
    if command -v podman &>/dev/null; then
        podman_sql_count=$(podman ps --no-trunc | grep -c '/opt/mssql/bin/sqlservr')
        if (( podman_sql_count > 0 )); then
            is_podman_sql_containers="YES"
        fi
    fi

    # Check for running podman SQL containers only if docker is not installed
    if [[ "$is_container_runtime_service_installed" == "NO" ]] && command -v podman &>/dev/null; then
        podman_sql_count_no_docker_runtime=$(podman ps --no-trunc | grep -c '/opt/mssql/bin/sqlservr')
        if (( podman_sql_count_no_docker_runtime > 0 )); then
            is_podman_sql_containers_no_docker_runtime="YES"
        fi
    fi
}

#when pssdiag is running inside, kubernetes, pod or container. get the status
pssdiag_inside_container_get_instance_status()
{
	is_instance_inside_container_active="NO"
	#Check if we are runing in kubernetes pod or inside container, sql parent process should have PID=1
	#first check, we should have no systemd
	if (! echo "$(readlink /sbin/init)" | grep systemd >/dev/null 2>&1); then
		#starting sql process is 1
		if [[ "$(ps -C sqlservr -o pid= | head -n 1 | tr -d ' ')" == "1" ]]; then
			is_instance_inside_container_active="YES"
		fi
	fi
}

#Check if we are running inside WSL
get_wsl_instance_status()
{
	is_host_instance_inside_wsl="NO"
  wsl_version="N/A"	 
  if grep -qi "microsoft" /proc/version; then
      if uname -r | grep -qi "microsoft-standard"; then
          is_host_instance_inside_wsl="YES"
          wsl_version="WSL2"
      else
          is_host_instance_inside_wsl="YES"
          wsl_version="WSL1"
      fi
  else
      is_host_instance_inside_wsl="NO"
  fi
}

get_servicemanager_and_sqlservicestatus()
{
	servicemanager="unknown"
	sqlservicestatus="unknown"

	get_container_instance_status
	get_host_instance_status
	pssdiag_inside_container_get_instance_status

	if [[ "${1}" == "host_instance" ]] && [[ "${is_host_instance_service_installed}" == "YES" ]]; then
		if [[ ${is_host_instance_process_running} == "YES" ]]; then
			sqlservicestatus="active"
			servicemanager="systemd"
		else
			sqlservicestatus="unknown"
			servicemanager="systemd"
		fi
	fi
	
	#Check if sql is started by supervisor
	if [[ "${1}" == "host_instance" ]] && [[ "${sqlservicestatus}" == "unknown" ]]; then
		supervisorctl status mssql-server >/dev/null 2>&1 && { sqlservicestatus="active"; servicemanager="supervisord"; } || { sqlservicestatus="unknown"; servicemanager="unknown"; }	
	fi

	#Check if sql is running in docker
	if [[ "${1}" == "container_instance" ]] && [[ ! -z "$(docker ps -q --filter name=${2})" ]]; then
		sqlservicestatus="active"
		servicemanager="docker"
	fi

	#Check if we are runing in kubernetes pod or inside container, sql parent process should have PID=1
	#first check, we should have no systemd
	if (! echo "$(readlink /sbin/init)" | grep systemd >/dev/null 2>&1); then
		#starting sql process is 1
		if [[ "$(ps -C sqlservr -o pid= | head -n 1 | tr -d ' ')" == "1" ]]; then
			sqlservicestatus="active"
			servicemanager="none"
		fi
	fi
}


sql_connect()
{
  MAX_ATTEMPTS=3
	attempt_num=1
	sqlconnect=0
	find_sqlcmd
	get_servicemanager_and_sqlservicestatus ${1} ${2}

  if [[ "$attempt_num" -eq 1 ]] ; then 
    logger "Starting connectivity routine" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
  fi

	if [[ "${sqlservicestatus}" == "unknown" ]]; then
		return $sqlconnect
	fi
	
	auth_mode=${4}
	CONN_AUTH_OPTIONS=''
	sqlconnect=0

	#force SQL Authentication when PSSDiag is running from inside Container
	if [[ $is_instance_inside_container_active == "YES" ]]; then auth_mode="SQL"; fi

	#if the user selected NONE Mode, ask then about what they need to use to this instance we are trying to connect to
	while [[ "${auth_mode}" != "SQL" ]] && [[ "${auth_mode}" != "AD" ]]; do
		read -r -p $'\e[1;34mSelect Authentication Mode: 1 SQL Authentication (Default), 2 AD Authentication: \e[0m' lmode < /dev/tty 2> /dev/tty
		lmode=${lmode:-1}
		if [ 1 = $lmode ]; then
			auth_mode="SQL"
		fi
		if [ 2 = $lmode ]; then
			auth_mode="AD"
		fi
	done 

	#Check if we have valid AD ticket before moving forward
	#making sure that klist is installed
	if ( command -v klist 2>&1 >/dev/null ); then 
		check_ad_cache=$(klist -l | tail -n +3 | awk '!/Expired/' | wc -l)
		if [[ "$check_ad_cache" == 0 ]] && [[ "$auth_mode" == "AD" ]]; then
      logger "AD Authentication was selected as Authentication mode to connect to sql, however, no Kerberos credentials found in default cache, they may have expired" "warn" "1" "0" "${pssdiag_log:-/dev/null}" "${0##*/}" 
      logger "AD Authentication will fail" "warn" "1" "0" "${pssdiag_log:-/dev/null}" "${0##*/}" 
      logger "to correct this, run 'sudo kinit user@DOMAIN.COM' in a separate terminal with AD user that is allowed to connect to sql server, then press enter in this terminal." "warn" "1" "0" "${pssdiag_log:-/dev/null}" "${0##*/}" 
      echo ""
      read -p "Press enter to continue..." < /dev/tty 2> /dev/tty
      echo ""
		fi
	fi

  logger "Establishing SQL connection to ${1} ${2} on port ${3} using ${auth_mode} authentication" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	
	#Test SQL Authentication, we allow them to try few times using SQL Auth
	if [[ $auth_mode = "SQL" ]]; then
		while [[ $attempt_num -le $MAX_ATTEMPTS ]]
		do
			#container do not connect using thier names if they do not have DNS record. so safer to connect using local host and container port
			## all of them its safer to use HOSTNAME, leaving this condition per instance type for now... force HOSTNAME
			if [ ${1} == "container_instance" ]; then
				SQL_SERVER_NAME="${HOSTNAME},${3}"
			fi
			if [ ${1} == "host_instance" ]; then
				SQL_SERVER_NAME="${HOSTNAME},${3}"
			fi
			if [ ${1} == "instance" ]; then
				SQL_SERVER_NAME="${HOSTNAME},${3}"
			fi
	    
      #prompt for credentials for SQL authentication
      echo ""
			read -r -p $'\e[1;34mEnter SQL UserName: \e[0m' XsrX < /dev/tty 2> /dev/tty
			read -s -r -p $'\e[1;34mEnter User Password: \e[0m' XssX < /dev/tty 2> /dev/tty
      echo ""

      #try to connect
			error_output=$("$SQLCMD" -S "$SQL_SERVER_NAME" -U "$XsrX" -P "$XssX" -C -Q "select @@version" 2>&1 >/dev/null)
			if [[ $? -eq 0 ]]; then
				sqlconnect=1
        echo ""
        logger "Successfully connected to ${1} ${2} on port ${3} using ${auth_mode} authentication" "info_green" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
				sql_ver=$("$SQLCMD" -S$SQL_SERVER_NAME -U$XsrX -P$XssX -C -Q"PRINT CONVERT(NVARCHAR(128), SERVERPROPERTY('ProductVersion'))")
        logger "SQL Server version  ${sql_ver}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
				CONN_AUTH_OPTIONS="-U$XsrX -P$XssX"
				break
			else
        echo ""
        #in case there is login fails, get each line of the error and log it
        while IFS= read -r line; do
            logger "${line}" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        done <<< "$error_output"
        logger "SQL login failed for ${1} ${2}, refer to the above lines for errors, Attempt ${attempt_num} of ${MAX_ATTEMPTS}, Please try again" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			fi
			attempt_num=$(( attempt_num + 1 ))
		done
	else
		#Test AD Authentication
		#container configured with AD Auth has DNS record so we can connect using thier name and container port
		if [ ${1} == "container_instance" ]; then
			SQL_SERVER_NAME="${2},${3}"
		fi
		if [ ${1} == "host_instance" ]; then
			SQL_SERVER_NAME="${HOSTNAME},${3}"
		fi
		  #try to connect
      error_output=$("$SQLCMD" -S$SQL_SERVER_NAME -E -C -Q"select @@version" 2>&1 >/dev/null)
    	if [[ $? -eq 0 ]]; then   	
        sqlconnect=1;
        CONN_AUTH_OPTIONS='-E'
        logger "Successfully connected to ${1} ${2} on port ${3} using ${auth_mode} authentication" "info_green" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        sql_ver=$("$SQLCMD" -S$SQL_SERVER_NAME -E -C -Q"PRINT CONVERT(NVARCHAR(128), SERVERPROPERTY('ProductVersion'))")
        logger "SQL Server version  ${sql_ver}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		  else
        #in case AD Authentication fails, get each line of the error and log it
        while IFS= read -r line; do
            logger "${line}" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        done <<< "$error_output"
        logger "AD Authentication failed for ${1} ${2}, refer to the above lines for errors" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        #Switch to SQL Authentication
        logger "Switching to SQL Authentication for ${1} ${2}" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        sql_connect ${1} ${2} ${3} "SQL"
		fi
	fi
	#set the orginal connect method to allow the next instance to select its own method
	return $sqlconnect	
}

get_sql_log_directory()
{
CONFIG_NAME="defaultlogdir"
DEFAULT_VALUE="/var/opt/mssql/log"

if [[ "$1" == "host_instance" ]]; then
        FILE_EXISTS=$(sh -c "test -f ${MSSQL_CONF} && echo 'exists' || echo 'not exists'")
        if [[ "${FILE_EXISTS}" == "exists" ]]; then
                logdir=`cat ${MSSQL_CONF} | grep -i ${CONFIG_NAME} | sed 's/ *= */=/g' | awk -F '=' '{ print $2}'`
                if [[ ${logdir} != "" ]] ; then
                        echo "${logdir}" | tee -a $pssdiag_log
                else
                        echo "${DEFAULT_VALUE}" | tee -a $pssdiag_log
                fi
        else
                echo "${DEFAULT_VALUE}" | tee -a $pssdiag_log
        fi
fi

if [[ "$1" == "container_instance" ]]; then
        FILE_EXISTS=$(docker exec ${3} sh -c "test -f ${MSSQL_CONF} && echo 'exists' || echo 'not exists'")
        if [[ "${FILE_EXISTS}" == "exists" ]]; then
                logdirline=$(docker exec ${3} sh -c "cat ${MSSQL_CONF} | grep -i ${CONFIG_NAME}")
                logdir=`echo ${tcpportline} | sed 's/ *= */=/g' | awk -F '=' '{ print $2}'`
                if [[ ${logdir} != "" ]] ; then
                        echo "${logdir}" | tee -a $pssdiag_log
                else
                        echo "${DEFAULT_VALUE}" | tee -a $pssdiag_log
                fi
        else
                echo "${DEFAULT_VALUE}" | tee -a $pssdiag_log
        fi
fi
}

#get_host_conf_option '/var/opt/mssql/mssql.conf' 'sqlagent' 'errorlogfile' '/var/opt/mssql/log/sqlagent'
#get_host_conf_option '/var/opt/mssql/mssql.conf' 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog'
#get_host_conf_option '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' 'NA' 
get_host_conf_option()
{
  unset get_host_conf_option_result
  unset config_section_found
  while IFS= read -r line; do
    
    #skip comments
    if [[ "${line}" == \#* ]]; then
        continue
    fi

    config_section=$(echo "${line}" | tr -d '[]' | xargs)
    if [[ "${config_section}" == "${2}" ]]; then
      config_section_found=1
    fi
    option=$(echo ${line} | cut -d "=" -f1 | xargs )
    if [[ "${config_section_found}" == 1 ]] && [[ "${option}" == "${3}" ]]; then
      get_host_conf_option_result=$(echo ${line//"$option"/} | tr -d '=' | xargs) 
      break 
    fi
  done < $1

  if [ "${get_host_conf_option_result}" ]; then
    logger "Host instance ${HOSTNAME} conf file ${1} setting option [${2}] ${3} is set to : ${get_host_conf_option_result}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
  elif [ "${4}" == "NA" ]; then
    logger "Host instance ${HOSTNAME} conf file ${1} setting option [${2}] ${3} is not set in the conf file, no default for this setting" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
    get_host_conf_option_result="NA"
  else
    logger "Host instance ${HOSTNAME} conf file ${1} setting option [${2}] ${3} is not set in the conf file, using the default : ${4}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
    get_host_conf_option_result=${4}
  fi
}

#get_docker_conf_option '/var/opt/mssql/mssql.conf' 'sqlagent' 'errorlogfile' '/var/opt/mssql/log/sqlagent' 'dockername'
#get_docker_conf_option '/var/opt/mssql/mssql.conf' 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog' 'dockername'
#get_docker_conf_option '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' 'NA' 'dockername'
get_docker_conf_option()
{
  unset get_docker_conf_option_result
  unset config_section_found

  tmpcontainertmpfile="./$(uuidgen).pssdiag.mssql.conf.tmp"
  echo "$(docker exec --user root ${5} sh -c "cat ${1}")" > "$tmpcontainertmpfile"

  while IFS= read -r line; do

    #skip comments
    if [[ "${line}" == \#* ]]; then
        continue
    fi
    
    config_section=$(echo "${line}" | tr -d '[]' | xargs)
    if [[ "${config_section}" == "${2}" ]]; then
      config_section_found=1
    fi
    option=$(echo ${line} | cut -d "=" -f1 | xargs)
    if [[ "${config_section_found}" == 1 ]] && [[ "${option}" == "${3}" ]]; then
      get_docker_conf_option_result=$(echo ${line//"$option"/} | tr -d '=' | xargs) 
      break 
    fi
  done < "$tmpcontainertmpfile"

  #Remove tmpcontainertmpfile
  rm "$tmpcontainertmpfile"
  
  if [ "${get_docker_conf_option_result}" ]; then
    logger "Container instance ${5} conf file ${1} setting option [${2}] ${3} is set to : ${get_docker_conf_option_result}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
  elif [ "${4}" == "NA" ]; then
    logger "Container instance ${5} conf file ${1} setting option [${2}] ${3} is not set in the conf file, no default for this setting" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
    get_docker_conf_option_result="NA"
  else
    logger "Container instance ${5} conf file ${1} setting option [${2}] ${3} is not set in the conf file, using the default : ${4}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
    get_docker_conf_option_result=${4}
  fi
}

validate_scenario_file() {
  local file="$1"
  local invalid=0
  local minimum_collectors=0

  # Allowed variables and their valid values (regex or list, matched against lowercased values)
  declare -A allowed_values
  allowed_values[SCENARIO_COLLECTION_TYPE]="^(static|perf)$"
  allowed_values[COLLECT_HOST_SQL_INSTANCE]="^(yes|no)$"
  # allow ALL or a container NAME (not ID)
  allowed_values[COLLECT_CONTAINER]="^(all|[A-Za-z0-9_.-]+)$"
  allowed_values[COLLECT_HOST_OS_INFO]="^(yes|no)$"
  allowed_values[COLLECT_OS_LOGS]="^(yes|no)$"
  allowed_values[COLLECT_OS_CONFIG]="^(yes|no)$"
  allowed_values[COLLECT_OS_COUNTERS]="^(yes|no)$"
  # must be positive (>0)
  allowed_values[OS_COUNTERS_INTERVAL]="^[1-9][0-9]*$"
  allowed_values[COLLECT_OS_HA_LOGS]="^(yes|no)$"
  allowed_values[COLLECT_OS_SEC_AD_LOGS]="^(yes|no)$"
  allowed_values[SQL_CONNECT_AUTH_MODE]="^(sql|ad|none)$"
  allowed_values[COLLECT_SQL_LOGS]="^(yes|no)$"
  allowed_values[COLLECT_SQL_DUMPS]="^(yes|no)$"
  allowed_values[COLLECT_SQL_HA_LOGS]="^(yes|no)$"
  allowed_values[COLLECT_SQL_SEC_AD_LOGS]="^(yes|no)$"
  allowed_values[COLLECT_SQL_CONFIG]="^(yes|no)$"
  allowed_values[COLLECT_PERFSTATS_SNAPSHOT]="^(yes|no)$"
  allowed_values[COLLECT_QUERY_STORE]="^(yes|no)$"
  allowed_values[COLLECT_SQL_BEST_PRACTICES]="^(yes|no)$"
  allowed_values[COLLECT_SQL_COUNTERS]="^(yes|no)$"
  # must be positive (>0)
  allowed_values[SQL_COUNTERS_INTERVAL]="^[1-9][0-9]*$"
  allowed_values[COLLECT_PERFSTATS]="^(yes|no)$"
  allowed_values[COLLECT_SQL_MEM_STATS]="^(yes|no)$"
  allowed_values[COLLECT_HIGHCPU_PERFSTATS]="^(yes|no)$"
  allowed_values[COLLECT_HIGHIO_PERFSTATS]="^(yes|no)$"
  allowed_values[COLLECT_LINUX_PERFSTATS]="^(yes|no)$"
  allowed_values[CUSTOM_COLLECTOR]="^(yes|no)$"
  allowed_values[COLLECT_EXTENDED_EVENTS]="^(yes|no)$"
  allowed_values[EXTENDED_EVENT_TEMPLATE]="^(pssdiag_xevent_lite|pssdiag_xevent_general|pssdiag_xevent_detailed)$"
  allowed_values[COLLECT_SQL_TRACE]="^(yes|no)$"
  allowed_values[SQL_TRACE_TEMPLATE]="^(pssdiag_trace_lite|pssdiag_trace_general|pssdiag_trace_detailed|pssdiag_trace_replication)$"

  # Keep this (used for "missing" pass)
  allowed_vars=("${!allowed_values[@]}")

  # Default values for each variable
  declare -A default_values
  default_values[SCENARIO_COLLECTION_TYPE]="STATIC"
  default_values[COLLECT_HOST_SQL_INSTANCE]="NO"
  default_values[COLLECT_CONTAINER]="ALL"
  default_values[COLLECT_HOST_OS_INFO]="NO"
  default_values[COLLECT_OS_LOGS]="NO"
  default_values[COLLECT_OS_CONFIG]="NO"
  default_values[COLLECT_OS_COUNTERS]="NO"
  default_values[OS_COUNTERS_INTERVAL]="15"
  default_values[COLLECT_OS_HA_LOGS]="NO"
  default_values[COLLECT_OS_SEC_AD_LOGS]="NO"
  default_values[SQL_CONNECT_AUTH_MODE]="SQL"
  default_values[COLLECT_SQL_LOGS]="NO"
  default_values[COLLECT_SQL_DUMPS]="NO"
  default_values[COLLECT_SQL_HA_LOGS]="NO"
  default_values[COLLECT_SQL_SEC_AD_LOGS]="NO"
  default_values[COLLECT_SQL_CONFIG]="NO"
  default_values[COLLECT_PERFSTATS_SNAPSHOT]="NO"
  default_values[COLLECT_QUERY_STORE]="NO"
  default_values[COLLECT_SQL_BEST_PRACTICES]="NO"
  default_values[COLLECT_SQL_COUNTERS]="NO"
  default_values[SQL_COUNTERS_INTERVAL]="15"
  default_values[COLLECT_PERFSTATS]="NO"
  default_values[COLLECT_SQL_MEM_STATS]="NO"
  default_values[COLLECT_HIGHCPU_PERFSTATS]="NO"
  default_values[COLLECT_HIGHIO_PERFSTATS]="NO"
  default_values[COLLECT_LINUX_PERFSTATS]="NO"
  default_values[CUSTOM_COLLECTOR]="NO"
  default_values[COLLECT_EXTENDED_EVENTS]="NO"
  default_values[EXTENDED_EVENT_TEMPLATE]="pssdiag_xevent_lite"
  default_values[COLLECT_SQL_TRACE]="NO"
  default_values[SQL_TRACE_TEMPLATE]="pssdiag_trace_lite"

  # User-friendly descriptions (used in messages)
  declare -A valid_desc
  valid_desc[SCENARIO_COLLECTION_TYPE]="static, perf"
  valid_desc[COLLECT_HOST_SQL_INSTANCE]="yes, no"  
  valid_desc[COLLECT_CONTAINER]="ALL or container NAME (not ID)"
  valid_desc[COLLECT_HOST_OS_INFO]="yes, no"
  valid_desc[COLLECT_OS_LOGS]="yes, no"
  valid_desc[COLLECT_OS_CONFIG]="yes, no"
  valid_desc[COLLECT_OS_COUNTERS]="yes, no"
  valid_desc[OS_COUNTERS_INTERVAL]="any positive integer"
  valid_desc[COLLECT_OS_HA_LOGS]="yes, no"
  valid_desc[COLLECT_OS_SEC_AD_LOGS]="yes, no"
  valid_desc[SQL_CONNECT_AUTH_MODE]="sql, ad, none"
  valid_desc[COLLECT_SQL_LOGS]="yes, no"
  valid_desc[COLLECT_SQL_DUMPS]="yes, no"
  valid_desc[COLLECT_SQL_HA_LOGS]="yes, no"
  valid_desc[COLLECT_SQL_SEC_AD_LOGS]="yes, no"
  valid_desc[COLLECT_SQL_CONFIG]="yes, no"
  valid_desc[COLLECT_PERFSTATS_SNAPSHOT]="yes, no"
  valid_desc[COLLECT_QUERY_STORE]="yes, no"
  valid_desc[COLLECT_SQL_BEST_PRACTICES]="yes, no"
  valid_desc[COLLECT_SQL_COUNTERS]="yes, no"
  valid_desc[SQL_COUNTERS_INTERVAL]="any positive integer"
  valid_desc[COLLECT_PERFSTATS]="yes, no"
  valid_desc[COLLECT_SQL_MEM_STATS]="yes, no"
  valid_desc[COLLECT_HIGHCPU_PERFSTATS]="yes, no"
  valid_desc[COLLECT_HIGHIO_PERFSTATS]="yes, no"
  valid_desc[COLLECT_LINUX_PERFSTATS]="yes, no"
  valid_desc[CUSTOM_COLLECTOR]="yes, no"
  valid_desc[COLLECT_EXTENDED_EVENTS]="yes, no"
  valid_desc[EXTENDED_EVENT_TEMPLATE]="pssdiag_xevent_lite, pssdiag_xevent_general, pssdiag_xevent_detailed"
  valid_desc[COLLECT_SQL_TRACE]="yes, no"
  valid_desc[SQL_TRACE_TEMPLATE]="pssdiag_trace_lite, pssdiag_trace_general, pssdiag_trace_detailed, pssdiag_trace_replication"

  # Extract variables and values from the file
  while IFS='=' read -r var val; do
    # Remove inline comments & spaces
    val="${val%%\#*}"
    val="${val// /}"

    # CHECK1: Check for unknown settings.
    if [[ ! -v "allowed_values[$var]" ]]; then
      logger "Invalid setting found '$var' in scenario file; this setting will be ignored" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
      continue
    fi

    # CHECK2: Case-insensitive value check, must be in the acceptable range for the setting.
    regex="${allowed_values[$var]}"
    val_lc="$(echo "$val" | tr '[:upper:]' '[:lower:]')"
    if ! [[ "$val_lc" =~ $regex ]]; then
      if [[ "$var" == "COLLECT_CONTAINER" ]]; then
        logger "Invalid value for $var: '$val'. Acceptable values are: ALL, or a container NAME (not ID)" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
      elif [[ "$var" == "OS_COUNTERS_INTERVAL" || "$var" == "SQL_COUNTERS_INTERVAL" ]]; then
        logger "Invalid value for $var: '$val'. Must be a positive integer (>0)" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
      else
        valid_upper=$(echo "${valid_desc[$var]}" | tr '[:lower:]' '[:upper:]')
        logger "Invalid value for $var: '$val'. Valid values are: $valid_upper" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
      fi
      invalid=1
    fi
  #Accept upper/lower var names; leading spaces allowed
  done < <(grep -E '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=' "$file" | sed 's/^[[:space:]]*//')

  # CHECK3: Check for missing settings, apply defaults will be done by Start and Stop scripts for missing settings
  counter=0
  for var in "${allowed_vars[@]}"; do
    if ! grep -q "^[[:space:]]*$var=" "$file"; then
      logger "Scenario file is missing '$var' setting; will apply the default value '${default_values[$var]}'" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	  ((counter++))
    fi
  done
  
  # CHECK4: At least one of the following settings is present COLLECT_HOST_SQL_INSTANCE and COLLECT_CONTAINER, 
  if ! grep -iq "^[[:space:]]*COLLECT_HOST_SQL_INSTANCE=" "$file" && ! grep -iq "^[[:space:]]*COLLECT_CONTAINER=" "$file"; then
	invalid=1
    logger "Scenario file is missing 'COLLECT_HOST_SQL_INSTANCE' and 'COLLECT_CONTAINER' settings; at least one of them must be present" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
  fi

  # CHECK5: At least one of the following settings has value to collect,  COLLECT_HOST_SQL_INSTANCE and COLLECT_CONTAINER, at least one of them must be present
  if ! grep -iq "^[[:space:]]*COLLECT_HOST_SQL_INSTANCE=YES" "$file" && ! grep -iqE "^[[:space:]]*COLLECT_CONTAINER=(ALL|[a-z0-9_-]+)" "$file"; then
    invalid=1
    logger "Both 'COLLECT_HOST_SQL_INSTANCE' and 'COLLECT_CONTAINER' are set incorrectly; at least one must be 'YES', 'ALL', or a valid container name" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
  fi

  # CHECK6: At least we must have one collector setting set to YES
  minimum_collectors=0
  for var in \
	COLLECT_OS_CONFIG \
	COLLECT_OS_COUNTERS \
	COLLECT_OS_LOGS \
	COLLECT_OS_HA_LOGS \
	COLLECT_OS_SEC_AD_LOGS \
	COLLECT_SQL_LOGS \
	COLLECT_SQL_DUMPS \
	COLLECT_SQL_HA_LOGS \
	COLLECT_SQL_SEC_AD_LOGS \
	COLLECT_SQL_CONFIG \
	COLLECT_PERFSTATS_SNAPSHOT \
	COLLECT_QUERY_STORE \
	COLLECT_SQL_BEST_PRACTICES \
	COLLECT_SQL_COUNTERS \
	COLLECT_PERFSTATS \
	COLLECT_SQL_MEM_STATS \
	COLLECT_HIGHCPU_PERFSTATS \
	COLLECT_HIGHIO_PERFSTATS \
	COLLECT_LINUX_PERFSTATS \
	CUSTOM_COLLECTOR \
	COLLECT_EXTENDED_EVENTS
  do
  if grep -iq "^[[:space:]]*$var=YES" "$file"; then
	minimum_collectors=1
  fi
 done

 if (( minimum_collectors == 0)); then
     logger "None of log collectors is set to YES, at least one log or trace collector needs to be set to YES" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	 invalid=1
 fi

  # CHECK7: If all variables are missing, likely an invalid file
  if (( counter == 30 )); then
  logger "there are no valid settings defined in the scenario file specified" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	invalid=1
  fi

  # Do not break callers: always return success after validating all content
  (( invalid )) && return 1 || return 0
}

logger()
{
  #parameters: message, level, color
  local msg="$1"
  local level="${2:-info}"  # Default level is 'info' if not provided
  local log_console="${3:-1}" # Default is 1, output to console, 0 means do not output to console
  local log_logfile="${4:-1}" # Default is 1, output to logfile, 0 means do not output to logfile
  local logfile="${5:-${pssdiag_log:-/dev/null}}" # Default to pssdiag_log if not provided
  local scriptfile="${6}" # Get the script name for logging
  local surround_char="${7:-=}" # Default surround char for header is '='
  local surround_type="${8:-0}" # Default surround type for header is '0' full surround, 1=side surround.
 
  #local vars
  local total_width=120
  local timestamp="$(date -u +"%D %T")$(date -u +"%H")"

  #color codes
  local color_reset="\x1B[0m"
  
  if [[ "$level" == "error" ]]; then
      msg_color="\x1B[31m"  # Red for errors
  elif [[ "$level" == "warn" ]]; then
      msg_color="\x1B[33m"  # Yellow for warnings
  elif [[ "$level" == "info" ]]; then
      msg_color="\x1B[0m"  # no color for info and default
  elif [[ "$level" == "info_green" ]]; then
      msg_color="\x1B[32m"  # Green for success
  elif [[ "$level" == "info_blue" ]]; then
      msg_color="\033[;94m"  # Blue for info
  elif [[ "$level" == "info_highlight" ]]; then
      msg_color="\x1B[7m"  # background highlight
  elif [[ "$level" == "header_blue" ]]; then
      msg_color="\033[;94m"  # Blue for headers
  elif [[ "$level" == "header_yellow" ]]; then
      msg_color="\033[0;33m"  # Yellow for headers
  fi

  #we only use info_highlight level to set color code, change it to info for logging purpose
  if [[ "$level" == "info_highlight" ]] || [[ "$level" == "info_green" ]] || [[ "$level" == "info_blue" ]]; then
      level="info"
  fi

  #level padding for alignment, max length is 6 char
  padded_level=$(printf "%-6s" "$level")

  #Scriptfile padding for alignment, max length is 26 char
  padded_scriptfile=$(printf "%-26s" "$scriptfile")

  #message prefix with timestamp
  msg_prefix="[$timestamp] $padded_level"

  #add . to the end of info, warn and error messages
  if [[ "$level" == "info" ]] || [[ "$level" == "error" ]] || [[ "$level" == "warn" ]]; then
      msg="$msg."
  fi

  #header level special formatting
  if [[ "$level" == "header_blue" ]] || [[ "$level" == "header_yellow" ]]; then
    # If the message is longer than total_width, truncate (optional behavior)
    if (( ${#msg} > total_width )); then
      msg=${msg:0:total_width}
    fi

    # surround_type 0
    if [[ $surround_type == 0 ]]; then
      msg_len=${#msg}
      left=$(( (total_width - msg_len) / 2 ))
      right=$(( total_width - msg_len - left ))  # ensures total is exactly 120

      # Build pads made of '=' only (do not touch msg)
      printf -v left_pad  '%*s' "$left"  ''
      printf -v right_pad '%*s' "$right" ''
      left_pad=${left_pad// /$surround_char}
      right_pad=${right_pad// /$surround_char}

      msg_prefix=""
      msg="${left_pad}${msg}${right_pad}"
    fi
    # surround_type 1
    if [[ $surround_type == 1 ]]; then
      # Calculate padding
      msg_length=${#msg}
      inner_length=$((total_width - 2))
      padding=$((inner_length - msg_length))

      # Split padding into left and right
      left_padding=$((padding / 2))
      right_padding=$((padding - left_padding))

      # Assign the final string to a variable
      msg_prefix=""
      msg=$(printf "$surround_char%${left_padding}s%s%${right_padding}s$surround_char" "" "$msg" "")  
    fi
  fi

  # Determine output destinations based on skip flags
  if [[ "$log_console" == 1 ]] && [[ "$log_logfile" == 1 ]]; then
      #log to both console and file
      #printf '%b%b%s%b\n' "$msg_prefix" "$msg_color" "$msg" "$color_reset" | tee >(sed -e 's/\x1b\[[0-9;]*m//g' >> "$logfile")
      printf '%b%b%s%b\n' "$msg_prefix" "$msg_color" "$msg" "$color_reset"
      printf '%b%b%s\n' "$padded_scriptfile" "$msg_prefix" "$msg" >> "$logfile" 
  fi

  if [[ "$log_console" == 0 ]] && [[ "$log_logfile" == 1 ]]; then
      #log to log file only
      #printf '%b%b%s%b\n' "$msg_prefix" "$msg_color" "$msg" "$color_reset" | sed -e 's/\x1b\[[0-9;]*m//g' >> "$logfile" | tee /dev/tty
      printf '%b%b%s\n' "$padded_scriptfile" "$msg_prefix" "$msg" >> "$logfile" 
  fi

  if [[ "$log_console" == 1 ]] && [[ "$log_logfile" == 0 ]]; then
      #log to console only
      printf '%b%b%s%b\n' "$msg_prefix" "$msg_color" "$msg" "$color_reset"
  fi

}