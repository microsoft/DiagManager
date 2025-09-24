#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

# Arguments:
#   1. Title
#   2. Command
#

# function capture_system_info_command()
# {
#     title=$1
#     command=$2

#     echo "=== $title ===" >> $infolog_filename
#     eval "$2 2>&1" >> $infolog_filename
#     echo "" >> $infolog_filename
# }

collect_docker_sql_ad_logs()
{

dockerid=$1
dockername=$2

logger "Collecting AD logs from container instance $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

#Check if we have configuration files. default container deployment with no mounts do not have /var/opt/mssql/mssql.conf so we need to check this upfront. 
docker_has_mssqlconf=$(docker exec --user root ${dockername} sh -c "(ls /var/opt/mssql/mssql.conf >> /dev/null 2>&1 && echo YES) || echo NO")
if [[ "${docker_has_mssqlconf}" == "YES" ]]; then
get_docker_conf_option '/var/opt/mssql/mssql.conf' 'network' 'kerberoskeytabfile' '' $dockername
SQL_SERVICE_KEYTAB_FILE=$get_docker_conf_option_result
docker_has_mssql_keytab=$(docker exec --user root ${dockername} sh -c "(ls ${SQL_SERVICE_KEYTAB_FILE} >> /dev/null 2>&1 && echo YES) || echo NO")
    if [[ "${docker_has_mssql_keytab}" == "NO" ]]; then
		logger "skipping collecting AD logs, there is no mssql.keytab file for container instance $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
    else
        #Collect krb5.conf from container
        krb5file=$(docker container inspect -f '{{range .Mounts}}{{printf "\n"}}{{.Destination}}{{end}}' ${dockername} | grep -e krb5.conf)
        if [[ "${krb5file}" ]]; then
            logger "Collecting krb5.conf file from container : $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
            docker cp $dockerid:$krb5file $outputdir/${dockername}_container_instance_krb5.conf | 2>/dev/null
        else	
            logger "Container ${dockername} has no krb5.conf" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        fi

        #Creating log file
        infolog_filename=$outputdir/${dockername}_container_instance_kerberos.info

        #Collect resolv.conf from container
		logger "Collecting resolv.conf from container instance $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        capture_system_info_command "cat /etc/resolv.conf" "docker exec --user root "${dockername}" sh -c \"cat /etc/resolv.conf\""

        #Collecting mssql.keytab klist information
        logger "Collecting mssql.keytab klist information from container instance $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        tmpcontainertmpfile="$outputdir/$(uuidgen).pssdiag.container.temp"
        docker cp $dockerid:${SQL_SERVICE_KEYTAB_FILE} ${tmpcontainertmpfile} | 2>/dev/null
        capture_system_info_command "klist -kte ${SQL_SERVICE_KEYTAB_FILE}" "klist -kte ${SQL_SERVICE_KEYTAB_FILE}"
		chmod u+w "$tmpcontainertmpfile"
        rm "$tmpcontainertmpfile"

        #Collecting service account kvno information     
        logger "Collecting service account kvno information from container instance $dockername" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        get_docker_conf_option '/var/opt/mssql/mssql.conf' 'network' 'privilegedadaccount' '' $dockername
		SQL_SERVICE_ACCOUNT_KVNO=$get_docker_conf_option_result

        if [ "${linuxdistro}" == "sles" ];then
            capture_system_info_command "Sql Service account /usr/lib/mit/bin/kvno: /usr/lib/mit/bin/kvno ${SQL_SERVICE_ACCOUNT_KVNO}" "/usr/lib/mit/bin/kvno ${SQL_SERVICE_ACCOUNT_KVNO}"
        else
            capture_system_info_command "Sql Service account kvno: kvno ${SQL_SERVICE_ACCOUNT_KVNO}" "kvno ${SQL_SERVICE_ACCOUNT_KVNO}"
        fi

        #check if krb5 logging was enabled at service level for container instance 
        SQL_CONTAINER_KRB5_TRACE=$(docker exec --user root ${dockername} env | grep "KRB5_TRACE" | grep KRB5_TRACE | sed -e "s/^KRB5_TRACE=//")
        if docker exec --user root ${dockername} test -e "${SQL_CONTAINER_KRB5_TRACE}"; then
            logger "Collecting sql service krb5 trace from container instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
            docker cp $dockerid:$SQL_CONTAINER_KRB5_TRACE $outputdir/${dockername}_container_instance_$(basename ${SQL_CONTAINER_KRB5_TRACE}) | 2>/dev/null
        fi
    fi
fi
}

#Starting the script
logger "Starting sql AD logs collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

if [[ -d "$1" ]] ; then
	outputdir="$1"
else
   working_dir="$PWD"
   # Make sure log directory in working directory exists
    mkdir -p $working_dir/output

   # Define files and locations
   outputdir="$working_dir/output"
	if [ "$EUID" -eq 0 ]; then
	group=$(id -gn "$SUDO_USER")
	chown "$SUDO_USER:$group" "$outputdir" -R
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
				collect_docker_sql_ad_logs $dockerid $dockername
			else			
				logger "Container not found : $dockername" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			fi
		else	
			# we need to iterate through all containers
			#dockerid_col=$(docker ps | grep 'mcr.microsoft.com/mssql/server' | awk '{ print $1 }')
			dockerid_col=$(docker ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }')
			for dockerid in $dockerid_col;
			do
				dockername=$(docker inspect -f "{{.Name}}" $dockerid | tail -c +2)
				collect_docker_sql_ad_logs $dockerid $dockername	
			done;
		fi
	fi
fi


if [[ "$COLLECT_HOST_SQL_INSTANCE" = [Yy][Ee][Ss] ]]; then
	#Creating log file
	get_host_instance_status
	#only check if its installed, if its installed then regradlesss if its active or note we need to collect the logs 
	if [ "${is_host_instance_service_installed}" == "YES" ]; then
		logger "Collecting AD logs from host instance ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

		infolog_filename=$outputdir/${HOSTNAME}_host_intance_Kerberos.info

		if [ -e "/var/opt/mssql/mssql.conf" ]; then

			#check if we have mssql.keytab file configured for host instance, the get_host_conf_option and store in var get_host_conf_option_result
			get_host_conf_option '/var/opt/mssql/mssql.conf' 'network' 'kerberoskeytabfile' 'NA'
			SQL_SERVICE_KEYTAB_FILE=$get_host_conf_option_result

			if [ ! -e $SQL_SERVICE_KEYTAB_FILE ]; then
				logger "skipping collecting AD logs, there is no mssql.keytab file for host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			else
				#Capture mssql.keytab klist information
				logger "Collecting mssql.keytab klist information from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
				capture_system_info_command "klist -kte ${SQL_SERVICE_KEYTAB_FILE}" "klist -kte ${SQL_SERVICE_KEYTAB_FILE}"
				
				# Capture service account knvo info
				logger "Collecting service account kvno information from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
				#check if we have mssql.keytab file configured for host instance, the get_host_conf_option and store in var get_host_conf_option_result
				get_host_conf_option '/var/opt/mssql/mssql.conf' 'network' 'privilegedadaccount' ''
				SQL_SERVICE_ACCOUNT_KVNO=$get_host_conf_option_result
				linuxdistro=`cat /etc/os-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}' | sed 's/"//g'`
				if [ "${linuxdistro}" == "sles" ];then
					capture_system_info_command "Sql Service account /usr/lib/mit/bin/kvno: /usr/lib/mit/bin/kvno ${SQL_SERVICE_ACCOUNT_KVNO}" "/usr/lib/mit/bin/kvno ${SQL_SERVICE_ACCOUNT_KVNO}"
				else
					capture_system_info_command "Sql Service account kvno: kvno ${SQL_SERVICE_ACCOUNT_KVNO}" "kvno ${SQL_SERVICE_ACCOUNT_KVNO}"
				fi
				#check if krb5 logging was enabled at service level for host instance
				if (systemctl -q is-enabled mssql-server); then
					SQL_HOST_KRB5_TRACE=$(systemctl cat mssql-server.service | grep KRB5_TRACE | sed -e "s/^Environment=KRB5_TRACE=//")
					if [ -e "${SQL_HOST_KRB5_TRACE}" ]; then
						logger "Collecting sql service krb5 trace from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
						cat "${SQL_HOST_KRB5_TRACE}" > $outputdir/${HOSTNAME}_host_instance_$(basename ${SQL_HOST_KRB5_TRACE})
					fi
				fi
			fi
		fi
	fi
fi

#Collect informaiton if we are running inside container
if [[ "$COLLECT_HOST_SQL_INSTANCE" = [Yy][Ee][Ss] ]]; then
	#Collecting errorlog* system_health*.xel log*.trc
	pssdiag_inside_container_get_instance_status
	if [ "${is_instance_inside_container_active}" == "YES" ]; then
		logger "Collecting AD logs from inside container instance ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		if [ ! -e "/var/opt/mssql/secrets/mssql.keytab" ]; then
			#check if krb5 logging was enabled at service level for instance
			SQL_INSTANCE_KRB5_TRACE=$(env | grep KRB5_TRACE | sed -e "s/^KRB5_TRACE=//")
			if [ -e "${SQL_INSTANCE_KRB5_TRACE}" ]; then
				logger "Collecting sql service krb5 trace from instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
				cat "${SQL_INSTANCE_KRB5_TRACE}" > $outputdir/${HOSTNAME}_instance_$(basename ${SQL_INSTANCE_KRB5_TRACE})
			fi

			if [ -e "/etc/krb5.conf" ]; then
				logger "Collecting sql service krb5.conf from instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
				cat /etc/krb5.conf > $outputdir/${HOSTNAME}_instance_krb5.conf
			fi
		fi
	fi
fi

exit 0