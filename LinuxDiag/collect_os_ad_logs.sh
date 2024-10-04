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
echo -e "$(date -u +"%T %D") Starting os ad logs collection..." | tee -a $pssdiag_log

if [[ -d "$1" ]] ; then
	outputdir="$1"
else
   working_dir="$PWD"
   # Make sure log directory in working directory exists
    mkdir -p $working_dir/output

   # Define files and locations
   outputdir="$working_dir/output"
fi

#collect sssd and krb5 logs
SYSLOGPATH=/var/log
NOW=`date +"%m_%d_%Y"`

if [ ! -e "/etc/krb5.conf" ]; then
    echo -e "$(date -u +"%T %D") skipping collecting os ad logs there is no krb5.conf for host instance..." | tee -a $pssdiag_log
else
    linuxdistro=`cat /etc/os-release | grep -i '^ID=' | head -n1 | awk -F'=' '{print $2}' | sed 's/"//g'`

    #Creating log file
    infolog_filename=$outputdir/${HOSTNAME}_os_Kerberos.info

    # Capture resolv info
    echo -e "$(date -u +"%T %D") Collecting resolv.conf information from host instance : ${HOSTNAME}..."
    capture_system_info_command "cat /etc/resolv.conf" "cat /etc/resolv.conf"

    # Capture realm info
    echo -e "$(date -u +"%T %D") Collecting realms information from host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
    capture_system_info_command "realm list" "realm list"

    #Capture krb5.keytab klist information 
    echo -e "$(date -u +"%T %D") Collecting keytab klist information from host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
    capture_system_info_command "klist -kte /etc/krb5.keytab" "klist -kte /etc/krb5.keytab"

    # Capture machine knvo info
    echo -e "$(date -u +"%T %D") Collecting machine knvo information from host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
    if [ "${linuxdistro}" == "sles" ];then
        capture_system_info_command "/usr/lib/mit/bin/kvno $(echo "${HOSTNAME}" | cut -d"." -f1)" "/usr/lib/mit/bin/kvno $(echo "${HOSTNAME}" | cut -d"." -f1)"
    else
        capture_system_info_command "kvno $(echo "${HOSTNAME}" | cut -d"." -f1)" "kvno $(echo "${HOSTNAME}" | cut -d"." -f1)"
    fi


    # we need to collect logs from host machine
    #Getting Krb5.conf and sssd.conf
    if [ -e "/etc/krb5.conf" ]; then
        echo -e "$(date -u +"%T %D") Collecting krb5.conf file information host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
        cat /etc/krb5.conf > $outputdir/${HOSTNAME}_os_krb5.conf
    fi
    if [ -e "/etc/sssd/sssd.conf" ]; then
        echo -e "$(date -u +"%T %D") Collecting sssd.conf file information host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
        cat /etc/sssd/sssd.conf > $outputdir/${HOSTNAME}_os_sssd.conf
    fi

    #get krb5 logging file from krb5.conf, the format could be FILE: or FILE=
    if [ -e "/etc/krb5.conf" ]; then
        DEFAULT_LOG=$(get_conf_optionx '/etc/krb5.conf' 'logging' 'default' 'FILE:/var/log/krb5/krb5kdc.log') | cut -d ":" -f2 | cut -d "=" -f2
        KDC_LOG=$(get_conf_optionx '/etc/krb5.conf' 'logging' 'kdc' 'FILE:/var/log/krb5/krb5kdc.log') | cut -d ":" -f2 | cut -d "=" -f2
        ADMIN_SERVER_LOG=$(get_conf_optionx '/etc/krb5.conf' 'logging' 'admin_server ' 'FILE:/var/log/krb5/krb5kdc.log') | cut -d ":" -f2 | cut -d "=" -f2
    fi

    sh -c 'tar -cjf "$0/$3_os_krb5_$1.tar.bz2" /var/lib/sss/pubconf/krb5.include.d/* "${KRB5_TRACE}" "@{DEFAULT_LOG}" "${KDC_LOG}" "${ADMIN_SERVER_LOG}" --ignore-failed-read --absolute-names 2>/dev/null'  "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"
    sh -c 'tar -cjf "$0/$3_os_sssd_$1.tar.bz2" $2/sssd/* --ignore-failed-read --absolute-names 2>/dev/null' "$outputdir" "$NOW" "$SYSLOGPATH" "$HOSTNAME"

fi

