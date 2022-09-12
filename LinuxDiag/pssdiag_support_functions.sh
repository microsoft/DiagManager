#!/bin/bash

MSSQL_CONF="/var/opt/mssql/mssql.conf"
outputdir="$PWD/output"
#SQL_LOG_DIR=${SQL_LOG_DIR:-"/var/opt/mssql/log"}
pssdiag_log="$outputdir/${HOSTNAME}_pssdiag.log"


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
   echo "collecting information from sql container instance : $dockername"
   SQL_LISTEN_PORT=$(get_sql_listen_port "container_instance" "2" $dockerid)
   #dynamically build?
   inspectcmd="docker inspect --format='{{(index (index .HostConfig.PortBindings \""
   inspectcmd+=$SQL_LISTEN_PORT
   inspectcmd+="/tcp\") 0).HostPort}}' $dockerid"
   dockerport=`eval $inspectcmd`
   # echo "${dockerport}"
}

get_servicemanager_and_sqlservicestatus()
{
	servicemanager="unknown"
	sqlservicestatus="unknown"
			
	#check if sql is started by systemd
	if [[ "${1}" == "host_instance" ]] && [[ "${sqlservicestatus}" == "unknown" ]]; then
		systemctl is-active mssql-server >/dev/null 2>&1 && { sqlservicestatus="active"; servicemanager="systemd"; } || { sqlservicestatus="unknown"; servicemanager="unknown"; }
	fi
	
	#Check if sql is started by supervisor
	if [[ "${1}" == "host_instance" ]] && [[ "${sqlservicestatus}" == "unknown" ]]; then
		supervisorctl status mssql-server >/dev/null 2>&1 && { sqlservicestatus="active"; servicemanager="supervisord"; } || { sqlservicestatus="unknown"; servicemanager="unknown"; }	
	fi
}


sql_connect()
{

	echo ""
	echo -e "\n=============================================================================================================================\n"
	echo "Attempting SQL connection to ${1} with name ${2} and port ${3}"

	MAX_ATTEMPTS=3
	attempt_num=1
	sqlconnect=0

	get_servicemanager_and_sqlservicestatus "host_instance"
	
	if [[ "${sqlservicestatus}" == "unknown" ]] && [[ "${servicemanager}" == "unknown" ]]; then
		return $sqlconnect
	fi

	
	while [ $SQL_CONNECT_AUTH_MODE != 'SQL' ] && [ $SQL_CONNECT_AUTH_MODE != 'AD' ]
	do
		
		read -r -p "  Select authentication type: 1 (SQL Authentication), 2 (Integrated Authentication)" lmode
		lmode=${lmode:-0}
		if [ 1 = $lmode ]; then
			SQL_CONNECT_AUTH_MODE='SQL'
		fi
		
		if [ 2 = $lmode ]; then
			SQL_CONNECT_AUTH_MODE='AD'
		fi

	done 

	CONN_AUTH_OPTIONS=''
	sqlconnect=0

	if [ $SQL_CONNECT_AUTH_MODE = 'SQL' ]; then

		while [ $attempt_num -le $MAX_ATTEMPTS ]
		do
        	#prompt for credentials for SQL authentication
	        read -r -p "        Enter SQL UserName: " sqluser
	        read -s -r -p "        Enter User Password: " pass
	        echo ""
	        /opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -U$sqluser -P$pass -Q"select @@version" 2>&1 >/dev/null
	        if [[ $? -eq 0 ]]; then
	        	sqlconnect=1
	        	echo "        SQL Connectivity test succeeded..."
				CONN_AUTH_OPTIONS="-U$sqluser -P$pass"
	        	break
	        else
			
        		echo "        Login Attempt failed - Attempt ${attempt_num} of ${MAX_ATTEMPTS}, Please try again"

	        fi
        	attempt_num=$(( attempt_num + 1 ))
		done
	
	else

		#integrated

		/opt/mssql-tools/bin/sqlcmd -S$SQL_SERVER_NAME -E -Q"select @@version" 2>&1 >/dev/null
	    if [[ $? -eq 0 ]]; then
	       	
			sqlconnect=1;
			CONN_AUTH_OPTIONS='-E'
			echo "        Integrated SQL Connectivity test succeeded..."
			
		fi

	fi
	echo -e "\n=============================================================================================================================\n"
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
                        echo "${logdir}"
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
                logdirline=$(docker exec ${3} sh -c "cat ${MSSQL_CONF} | grep -i ${CONFIG_NAME}")
                logdir=`echo ${tcpportline} | sed 's/ *= */=/g' | awk -F '=' '{ print $2}'`
                if [[ ${logdir} != "" ]] ; then
                        echo "${logdir}"
                else
                        echo "${DEFAULT_VALUE}"
                fi
        else
                echo "${DEFAULT_VALUE}"
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
echo ${result:-$3}

}

get_docker_conf_option()
{
unset result

#command="/opt/mssql/bin/mssql-conf get $2 $3"'| awk '"'"'!/^No setting/ {print $3}'"'" 

command="cat /var/opt/mssql/mssql.conf | awk -F' *= *' ""'"'$1 ~ '"/$2/"' {print $2}'"'"

result=$(docker exec ${1} sh -c "$command" --user root)

echo "docker conf option '$2 $3': ${result:-$4}">>$pssdiag_log
echo ${result:-$4}

}
#tee -a $pssdiag_log
