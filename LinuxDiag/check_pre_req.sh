#!/bin/bash

# this script checks if the required programs and packages are present on this system
# if any programs are not present then we cannot guarantee the reliability and usefullness of the data collection

# storing the status of the program install in local variables, 0 means program absent, 1 means program present
# if you add any new commands or programs in the data collection, make sure to add a check here

# include helper functions
source ./pssdiag_support_functions.sh

pssdiag_log="$outputdir/pssdiag.log"

echo -e "Starting pre-req checks..."  

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
		echo -e "\x1B[31mPSSDIAG is already running on this system. Only one instance of PSSDIAG is allowed to execute."  
		echo -e "Please stop the current run of PSSDIAG using the stop_collector script and then restart the collection. \x1B[0m" 
		exit 1
	else
		# we are good to continue
		sleep 0s
fi

# home directory check , we do not want pssdiag to run from home, xel will fail if we run from home.
current_dir="${PWD}"
USER_HOME=$(eval echo ~${SUDO_USER})
if [[ "${current_dir}" == "${USER_HOME}"* ]]; then
	home_directory_check=1
else
	home_directory_check=0
fi
if [[ "$home_directory_check" == 1 ]]
	then
		echo -e "\x1B[31mRunning PSSDiag from home directory is not supported."  
		echo -e "Please use another location, such as /tmp/pssdiag. \x1B[0m" 
		exit 1
	else
		# we are good to continue
		sleep 0s
fi

# Check if AD Authenticaiton was selected but no AD tickets are available
#check if klist exists, in case running inside container
if ( command -v klist 2>&1 >/dev/null ); then 
	check_ad_cache=$(klist -l | tail -n +3 | awk '!/Expired/' | wc -l)
	if [[ "$check_ad_cache" == 0 ]] && [[ "${4}" == "AD" ]]; then
		echo -e "\x1B[33mWarning: AD Authentication was selected as Authention mode to connect to sql, however, no Kerberos credentials found in default cache, they may have expired"  
		echo -e "Warning: AD Authentication will fail"
		echo -e "to correct this, run 'sudo kinit user@DOMAIN.COM' in a separate terminal with AD user that is allowed to connect to sql server, then press enter in this terminal. \x1B[0m" 
		read -p "Press enter to continue"
	fi
fi


# Check if we have AD klist entries, logged to AD 
#check if klist exists, in case running inside container
if ( command -v klist 2>&1 >/dev/null ); then 
	if [ -e "/etc/krb5.conf" ]; then
		check_ad_cache=$(klist -l | tail -n +3 | awk '!/Expired/' | wc -l)
		if [[ "$check_ad_cache" == 0 ]]
		then
			echo -e "\x1B[33mWarning: No Kerberos credentials found in default cache."  
			echo -e "\x1B[33mWarning: AD collectors will not be able to collect the key version number (kvno) information for host and SQL service accounts"  
			echo -e "To collect kvno information, run 'sudo kinit user@DOMAIN.COM' in a separate terminal, then press enter in this terminal." 
			echo -e "To ignore this warning press enter.\x1B[0m"
			read -p "Press enter to continue"
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
		echo -e "\x1B[33mA new version of PSSDiag for Linux is now available. You can find it at the following link https://github.com/microsoft/DiagManager/releases?q=Linux&expanded=true.\x1B[0m" 
	fi  
fi
# check if sqlcmd is installed, we need this to execute TSQL scripts [for future we need to expand or make generic to use any available sql command line tool]
check_sqlcmd="0"
if [[ ! -f $(ls -1 /opt/mssql-tools*/bin/sqlcmd | tail -n -1 2>/dev/null) ]] && [[ "$PRE_CHECK_SQL" == "YES" ]] ; then
	echo -e "\x1B[31mThe program sqlcmd from mssql-tools18 package is not installed on this system and is required for the data collection." 
	check_sqlcmd="0"
else
	check_sqlcmd="1"
fi

# check if iotop is installed, we need this to capture io related metrics from the system
check_iotop="0"
if ( !( hash iotop 2>/dev/null ) && ( [[ "$PRE_COLLECT_OS_COUNTERS" == "YES"  ]] ) ); then
        echo -e "\x1B[31mThe program iotop is not installed on this system and is required for the data collection." 
        check_iotop="0"
else
        check_iotop="1"
fi

# check if sysstat is installed, we need this to capture various performance metrics from the system
check_sysstat="0"
if ( ( !( hash iostat 2>/dev/null ) || !( hash mpstat 2>/dev/null ) || !( hash pidstat 2>/dev/null ) || !( hash sar 2>/dev/null ) ) &&  ( [[ "$PRE_COLLECT_OS_COUNTERS" == "YES" ]] ) ); then
        echo -e "\x1B[31mThe program's iostat/mpstat/pidstat/sar from sysstat package is not installed on this system and is required for the data collection." 
        check_sysstat="0"
else
        check_sysstat="1"
fi

# check if lsof is present and warn about it, this is used for process data collection in machine config scripts
if ( !( hash lsof 2>/dev/null ) ); then
	echo -e "\x1B[31mThe program lsof is not installed on this system and is used for the data collection, will continue without this.\x1B[0m" 
fi

# now ask the user what they want to do if any program is absent
if (( ("$check_sqlcmd" == "0") || ( "$check_iotop" == "0" ) || ( "$check_sysstat" == "0" ) )); then
	echo -e "If you do not have all the required programs installed data collection will not be reliable and complete! \x1B[0m" 
	read -p "Do you want to continue with data collection? Type Y or N : " check_input
	if [[ $check_input = [Yy] ]] 
	then
		exit 0
	else
		# we cannot continue execution, the main script will abort execution
                exit 1
	fi
else
	# we are good with all re-req checks, we can continue with data collection
	echo -e "Completed pre-req checks..." 
	exit 0
fi
