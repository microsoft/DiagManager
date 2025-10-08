#!/bin/bash

# this script checks if the required programs and packages are present on this system
# if any programs are not present then we cannot guarantee the reliability and usefullness of the data collection

# storing the status of the program install in local variables, 0 means program absent, 1 means program present
# if you add any new commands or programs in the data collection, make sure to add a check here

# include helper functions
source ./pssdiag_support_functions.sh

pssdiag_log="$outputdir/pssdiag.log"
find_sqlcmd

logger "Starting pre-req checks" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 

# first param to script indicates whether we plan to collect sql info which needs sqlcmd [in future we could allow custom sql tools to be able to collect the info]
if [[ "$1" == "YES" ]]; then
	PRE_CHECK_SQL="YES"
else
	PRE_CHECK_SQL="NO"
fi

# second param to script indicates whether we plan to collect os performance counters which requires most of the sysstat utilities
if [[ "$2" == "YES" ]]; then
        PRE_COLLECT_OS_COUNTERS="YES"
else
        PRE_COLLECT_OS_COUNTERS="NO"
fi

# third param to the script indicates the scenario used for PSSDIAG

# first we check if there is another pssdiag running
anchor_check=`ps aux | grep -i "pssdiag_anchor.sh" | grep -v "grep" | wc -l`
if (( "$anchor_check" >= 1 ))
	then
		logger "PSSDIAG is already running on this system. Only one instance of PSSDIAG is allowed to execute." "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		logger "Please stop the current run of PSSDIAG using the stop_collector script and then restart the collection" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		exit 1
	else
		# we are good to continue
		sleep 0s
fi

# home directory check , we do not want pssdiag to run from home, xel will fail if we run from home.
current_dir="${PWD}"
USER_HOME=$(eval echo ~$(id -un))
if [[ "${current_dir}" == "${USER_HOME}"* ]]; then
	home_directory_check=1
else
	home_directory_check=0
fi
if [[ "$home_directory_check" == 1 ]]
	then
		logger "Running PSSDiag from home directory is not supported" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		logger "Please use another location, such as /tmp/pssdiag" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		exit 1
	else
		# we are good to continue
		sleep 0s
fi

#Check if we have AD klist entries, logged to AD 
#check if klist exists, in case running inside container
if ( command -v klist 2>&1 >/dev/null ); then 
	if [ -e "/etc/krb5.conf" ]; then
		check_ad_cache=$(klist -l | tail -n +3 | awk '!/Expired/' | wc -l)
		if [[ "$check_ad_cache" == 0 ]]
		then
			logger "No Kerberos credentials found in default cache." "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			logger "AD collectors will not be able to collect kerberos related information" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
			logger "To collect kerberos related information, run 'sudo kinit user@DOMAIN.COM' before running PSSDiag" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
		fi
	fi
fi

#Check version
#check if curl exists, in case running inside container
if ( command -v curl 2>&1 >/dev/null ); then 
	publish_script_version=$(curl -s -m 15 https://raw.githubusercontent.com/microsoft/DiagManager/refs/heads/master/LinuxDiag/pssdiag_support_functions.sh | grep 'script_version=' | sed -e s/^script_version=// | tr -d "\"") 
	publish_script_version=${publish_script_version:-0}
	publish_version_s=$(date -d "${publish_script_version}" +'%s')
	current_version_s=$(date -d "${script_version}" +'%s')
	if [[ $publish_version_s > $current_version_s ]]; then
		logger "A new version of PSSDiag for Linux is now available. You can find it at the following link https://github.com/microsoft/DiagManager/releases?q=Linux&expanded=true" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	fi  
fi

# check if bzip2 is installed
check_bzip2="0"
if ( !( hash bzip2 2>/dev/null ) ); then
		logger "The program bzip2 is not installed on this system and is required for the data collection" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        check_bzip2="0"
else
        check_bzip2="1"
fi


# check if sqlcmd is installed, we need this to execute TSQL scripts [for future we need to expand or make generic to use any available sql command line tool]
check_sqlcmd="0"
if [[ $SQLCMD == "" ]] && [[ "$PRE_CHECK_SQL" == "YES" ]] ; then
	logger "The program sqlcmd from mssql-tools18 package is not installed on this system and is required for the data collection" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	check_sqlcmd="0"
else
	check_sqlcmd="1"
fi

# check if iotop is installed, we need this to capture io related metrics from the system
check_iotop="0"
if ( !( hash iotop 2>/dev/null ) && ( [[ "$PRE_COLLECT_OS_COUNTERS" == "YES"  ]] ) ); then
		logger "The program iotop is not installed on this system and is required for the data collection" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        check_iotop="0"
else
        check_iotop="1"
fi

# check if sysstat is installed, we need this to capture various performance metrics from the system
check_sysstat="0"
if ( ( !( hash iostat 2>/dev/null ) || !( hash mpstat 2>/dev/null ) || !( hash pidstat 2>/dev/null ) || !( hash sar 2>/dev/null ) ) &&  ( [[ "$PRE_COLLECT_OS_COUNTERS" == "YES" ]] ) ); then
		logger "The program's iostat/mpstat/pidstat/sar from sysstat package is not installed on this system and is required for the data collection" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
        check_sysstat="0"
else
        check_sysstat="1"
fi

# check if lsof is present and warn about it, this is used for process data collection in machine config scripts
if ( !( hash lsof 2>/dev/null ) ); then
	logger "The program lsof is not installed on this system and is used for the data collection, will continue without this" "warn" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
fi

# now ask the user what they want to do if any program is absent
if (( ("$check_sqlcmd" == "0") || ( "$check_iotop" == "0" ) || ( "$check_sysstat" == "0" ) || ( "$check_bzip2" == "0" ) )); then
	logger "PSSDiag cannot proceed because one or more required prerequisite programs are missing. Please install all required components before launching PSSDiag again" "error" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	exit 1
else
	# we are good with all re-req checks, we can continue with data collection
	logger "Completed pre-req checks" "info" "1" "1" "${pssdiag_log:-/dev/null}" "${0##*/}" 
	exit 0
fi
