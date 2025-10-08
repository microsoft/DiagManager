#!/bin/bash

# include helper functions
source ./pssdiag_support_functions.sh

# Arguments:
#   1. Title
#   2. Command
#

#function capture_system_info_command()
#{
#    title=$1
#    command=$2
#
#    echo "=== $title ===" >> $infolog_filename
#    eval "$2 2>&1" >> $infolog_filename
#    echo "" >> $infolog_filename
#}

#Starting the script
logger "Starting host AD logs collectors" "info_blue" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
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

#collect sssd and krb5 logs
SYSLOGPATH=/var/log
NOW=`date +"%m_%d_%Y"`

if [ ! -e "/etc/krb5.conf" ]; then
    logger "skipping collecting host AD logs there is no krb5.conf for host instance" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
else
    linuxdistro=`cat /etc/os-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}' | sed 's/"//g'`

    #Creating log file
    infolog_filename=$outputdir/${HOSTNAME}_os_Kerberos.info

    # Capture resolv info
    logger "Collecting resolv.conf information from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
    capture_system_info_command "cat /etc/resolv.conf" "cat /etc/resolv.conf"

    # Capture realm info
    logger "Collecting realms information from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
    capture_system_info_command "realm list" "realm list"

    #Capture krb5.keytab klist information
    logger "Collecting keytab klist information from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
    capture_system_info_command "klist -kte /etc/krb5.keytab" "klist -kte /etc/krb5.keytab"

    # Capture machine knvo info
    logger "Collecting machine knvo information from host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
    if [ "${linuxdistro}" == "sles" ];then
        capture_system_info_command "/usr/lib/mit/bin/kvno $(echo "${HOSTNAME}" | cut -d"." -f1)" "/usr/lib/mit/bin/kvno $(echo "${HOSTNAME}" | cut -d"." -f1)"
    else
        capture_system_info_command "kvno $(echo "${HOSTNAME}" | cut -d"." -f1)" "kvno $(echo "${HOSTNAME}" | cut -d"." -f1)"
    fi


    # we need to collect logs from host machine
    #Getting Krb5.conf and sssd.conf
    if [ -e "/etc/krb5.conf" ]; then
        logger "Collecting krb5.conf file information host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        cat /etc/krb5.conf > $outputdir/${HOSTNAME}_os_krb5.conf
    fi
    if [ -e "/etc/sssd/sssd.conf" ]; then
        logger "Collecting sssd.conf file information host instance : ${HOSTNAME}" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        cat /etc/sssd/sssd.conf > $outputdir/${HOSTNAME}_os_sssd.conf 2>/dev/null || true
    fi

    #get krb5 logging file from krb5.conf, the format could be FILE: or FILE=
    if [ -e "/etc/krb5.conf" ]; then
        get_host_conf_option '/etc/krb5.conf' 'logging' 'default' 'FILE:/var/log/krb5/krb5kdc.log'
        DEFAULT_LOG=$(echo "$get_host_conf_option_result" | cut -d ":" -f2 | cut -d "=" -f2)

        get_host_conf_option '/etc/krb5.conf' 'logging' 'kdc' 'FILE:/var/log/krb5/krb5kdc.log'
        KDC_LOG=$(echo "$get_host_conf_option_result" | cut -d ":" -f2 | cut -d "=" -f2)

        get_host_conf_option '/etc/krb5.conf' 'logging' 'admin_server' 'FILE:/var/log/krb5/krb5kdc.log'
        ADMIN_SERVER_LOG=$(echo "$get_host_conf_option_result" | cut -d ":" -f2 | cut -d "=" -f2)
    fi

    sh -c 'tar -cjf "$0/$3_os_krb5_$1.tar.bz2" /var/lib/sss/pubconf/krb5.include.d/* "${KRB5_TRACE}" "@{DEFAULT_LOG}" "${KDC_LOG}" "${ADMIN_SERVER_LOG}" --ignore-failed-read --absolute-names 2>/dev/null'  "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
    sh -c 'tar -cjf "$0/$3_os_sssd_$1.tar.bz2" $2/sssd/* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"

fi

exit 0