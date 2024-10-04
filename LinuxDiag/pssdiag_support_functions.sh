#!/bin/bash

script_version="20241001"
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
	is_host_instnace_service_active="NO"

	#Check if we are at host/systemd
	if (echo "$(readlink /sbin/init)" | grep systemd >/dev/null 2>&1); then
		if [ "$(systemctl list-units -all | grep mssql-server.service 2>/dev/null)" ]; then
			is_host_instance_service_installed="YES"
			if (systemctl -q is-enabled mssql-server); then
				is_host_instance_service_enabled="YES"
			else
				is_host_instance_service_enabled="NO"
			fi
			if (systemctl -q is-active mssql-server); then
				is_host_instnace_service_active="YES"
			else
				is_host_instnace_service_active="NO"
			fi
		else
			is_host_instance_service_installed="NO"
		fi
	fi
}

#Checking containers status, including podman
get_container_instance_status()
{
	is_container_runtime_service_installed="NO"
	is_container_runtime_service_enabled="NO"
	is_container_runtime_service_active="NO"


	#Check first if we are at host/systemd
	if (echo "$(readlink /sbin/init)" | grep systemd >/dev/null 2>&1); then
		if [ "$(systemctl list-units --type=service --state=active | grep docker 2>/dev/null)" ]; then
			is_container_runtime_service_installed="YES"
			if (systemctl -q is-enabled docker); then
				is_container_runtime_service_enabled="YES"
			else
				is_container_runtime_service_enabled="NO"
			fi
			if (systemctl -q is-active docker); then
				is_container_runtime_service_active="YES"
			else
				is_container_runtime_service_active="NO"
			fi
		else
			is_container_runtime_service_installed="NO"
		fi
	fi
	
	#Check if we podman containers running 
	is_podman_sql_containers="NO"
	if [[ is_container_runtime_service_installed="NO" ]] && ( command -v podman &> /dev/null ); then
    	    podman_sql_containers=$(podman ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }' | wc -l)
        	if [[ $podman_sql_containers > 0  ]]; then
            	is_podman_sql_containers="YES"
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

get_servicemanager_and_sqlservicestatus()
{
	servicemanager="unknown"
	sqlservicestatus="unknown"

	get_container_instance_status
	get_host_instance_status
	pssdiag_inside_container_get_instance_status
	#check if sql is started by systemd
	#if [[ "${1}" == "host_instance" ]] && [[ "${sqlservicestatus}" == "unknown" ]]; then
	#	systemctl is-active mssql-server >/dev/null 2>&1 && { sqlservicestatus="active"; servicemanager="systemd"; } || { sqlservicestatus="unknown"; servicemanager="unknown"; }
	#fi
	if [[ "${1}" == "host_instance" ]] && [[ "${is_host_instance_service_installed}" == "YES" ]]; then
		if [[ ${is_host_instnace_service_active} == "YES" ]]; then
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

	#Check if sql is running on docker
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
		echo "$(date -u +"%T %D") SQL server is configured to run under ${servicemanager}" >> $pssdiag_log
		echo "$(date -u +"%T %D") SQL Server is status ${sqlservicestatus}" >> $pssdiag_log
}


sql_connect()
{
	echo -e "\x1B[2;34m============================================================================================================\x1B[0m" | tee -a $pssdiag_log

	MAX_ATTEMPTS=3
	attempt_num=1
	sqlconnect=0

	get_servicemanager_and_sqlservicestatus ${1} ${2}
	
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
		read -r -p $'\e[1;34mSelect Authentication Mode: 1 SQL Authentication (Default), 2 AD Authentication: \e[0m' lmode
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
			echo -e "\x1B[33mWarning: AD Authentication was selected as Authentication mode to connect to sql, however, no Kerberos credentials found in default cache, they may have expired"  
			echo -e "Warning: AD Authentication will fail"
			echo -e "to correct this, run 'sudo kinit user@DOMAIN.COM' in a separate terminal with AD user that is allowed to connect to sql server, then press enter in this terminal. \x1B[0m" 
			read -p "Press enter to continue"
		fi
	fi

	echo -e "Establishing SQL connection to ${1} ${2} and port ${3} using ${auth_mode} authentication mode" | tee -a $pssdiag_log
	
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
			read -r -p $'\e[1;34mEnter SQL UserName: \e[0m' XsrX
			read -s -r -p $'\e[1;34mEnter User Password: \e[0m' XssX
			echo "" | tee -a $pssdiag_log
			$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME -U$XsrX -P$XssX -C -Q"select @@version" 2>&1 >/dev/null
			if [[ $? -eq 0 ]]; then
				sqlconnect=1
				echo -e "\x1B[32mConnection was successful....\x1B[0m" | tee -a $pssdiag_log
				CONN_AUTH_OPTIONS="-U$XsrX -P$XssX"
				break
			else
				echo -e "\x1B[31mLogin Attempt failed - Attempt ${attempt_num} of ${MAX_ATTEMPTS}, Please try again\x1B[0m" | tee -a $pssdiag_log
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
		$(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1) -S$SQL_SERVER_NAME -E -C -Q"select @@version" 2>&1 >/dev/null
    	if [[ $? -eq 0 ]]; then   	
			sqlconnect=1;
			CONN_AUTH_OPTIONS='-E'
			echo -e "\x1B[32mConnection was successful....\x1B[0m" | tee -a $pssdiag_log
		else
			#in case AD Authentication fails, try again using SQL Authentication for this particular instance 
			echo -e "\x1B[33mWarning: AD Authentication failed for ${1} ${2}, refer to the above lines for errors, switching to SQL Authentication for ${1} ${2}" | tee -a $pssdiag_log
			sql_connect ${1} ${2} ${3} "SQL"
		fi
	fi
	#set the orginal connect method to allow the next instance to select its own method
	#echo -e "\x1B[34m============================================================================================================\x1B[0m" | tee -a $pssdiag_log
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


#$(get_conf_option 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog')
get_conf_option()
{
unset result
#result=$(/opt/mssql/bin/mssql-conf get $1 $2 | awk '!/^No setting/ {print $3}')
result=$(cat /var/opt/mssql/mssql.conf | awk  -F' *= *' '$1 ~ '"/$2/"' {print $2}')

echo "host conf option '$1 $2': ${result:-$3}">>$pssdiag_log 
echo ${result:-$3} | tee -a $pssdiag_log

}

get_docker_conf_option()
{
unset result

#command="/opt/mssql/bin/mssql-conf get $2 $3"'| awk '"'"'!/^No setting/ {print $3}'"'" 

command="cat /var/opt/mssql/mssql.conf | awk -F' *= *' ""'"'$1 ~ '"/$2/"' {print $2}'"'"

result=$(docker exec ${1} sh -c "$command" --user root)

echo "docker conf option '$2 $3': ${result:-$4}">>$pssdiag_log | tee -a $pssdiag_log
echo ${result:-$4} | tee -a $pssdiag_log

}

#get_conf_optionx '/var/opt/mssql/mssql.conf' 'sqlagent' 'errorlogfile' '/var/opt/mssql/log/sqlagent'
#get_conf_optionx '/var/opt/mssql/mssql.conf' 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog'
#get_conf_optionx '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' '/var/opt/mssql/log/security.log'
get_conf_optionx()
{
unset result
unset config_section_found
while IFS= read -r line; do
	config_section=$(echo "${line}" | tr -d '[]')
	if [[ "${config_section}" == "${2}" ]]; then
		config_section_found=1
	fi
	option=$(echo ${line} | cut -d " " -f1)
	if [[ "${config_section_found}" == 1 ]] && [[ "${option}" == "${3}" ]]; then
		result=$(echo ${line//"$option"/} | tr -d '=') 
		break 
	fi
done < $1
if [ -z "${result}" ]; then
	echo "$(date -u +"%T %D") Reading host ${HOSTNAME} conf read from option ${1} option ${2} ${3}: ${result:-$4}">>$pssdiag_log
fi
echo ${result:-$4} 
}

#get_conf_optionx '/var/opt/mssql/mssql.conf' 'sqlagent' 'errorlogfile' '/var/opt/mssql/log/sqlagent' 'dockername'
#get_conf_optionx '/var/opt/mssql/mssql.conf' 'filelocation' 'errorlogfile' '/var/opt/mssql/log/errorlog' 'dockername'
#get_conf_optionx '/var/opt/mssql/logger.ini' 'Output:sql' 'filename' '/var/opt/mssql/log/security.log' 'dockername'
get_docker_conf_optionx()
{
unset result
unset config_section_found

tmpcontainertmpfile="./$(uuidgen).pssdiag.mssql.conf.tmp"
echo "$(docker exec --user root ${5} sh -c "cat ${1}")" > "$tmpcontainertmpfile"

while IFS= read -r line; do
	config_section=$(echo "${line}" | tr -d '[]')
	if [[ "${config_section}" == "${2}" ]]; then
		config_section_found=1
	fi
	option=$(echo ${line} | cut -d " " -f1)
	if [[ "${config_section_found}" == 1 ]] && [[ "${option}" == "${3}" ]]; then
		result=$(echo ${line//"$option"/} | tr -d '=') 
		break 
	fi
done < "$tmpcontainertmpfile"

#Remove tmpcontainertmpfile
rm "$tmpcontainertmpfile"
if [ -z "${result}" ]; then
	echo "$(date -u +"%T %D") Reading container ${5} conf read from ${1} option ${2} ${3}: ${result:-$4}">>$pssdiag_log
fi
echo ${result:-$4} 
}


#tee -a $pssdiag_log
