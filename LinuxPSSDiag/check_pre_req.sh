#!/bin/bash

# this script checks if the required programs and packages are present on this system
# if any programs are not present then we cannot guarantee the reliability and usefullness of the data collection

# storing the status of the program install in local variables, 0 means program absent, 1 means program present
# if you add any new commands or programs in the data collection, make sure to add a check here

echo "Starting pre-req checks"

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
		echo -e "\x1B[31m	PSSDIAG is already running on this system. Only one instance of PSSDIAG is allowed to execute."
		echo -e "	Please stop the current run of PSSDIAG using the stop_collector script and then restart the collection \x1B[0m"
		exit 1
	else
		# we are good to continue
		sleep 0s
fi

# check if sqlcmd is installed, we need this to execute TSQL scripts [for future we need to expand or make generic to use any available sql command line tool]
check_sqlcmd="0"
sqlcmd_path="/opt/mssql-tools/bin/sqlcmd"
if ( [ ! -f "$sqlcmd_path" ] && ( [[ "$PRE_CHECK_SQL" == "YES" ]]  ) ); then
	echo -e "\x1B[31m	The program sqlcmd from mssql-tools package is not installed on this system and is required for the data collection"
	check_sqlcmd="0"
else
	check_sqlcmd="1"
fi

# check if iotop is installed, we need this to capture io related metrics from the system
check_iotop="0"
if ( !( hash iotop 2>/dev/null ) && ( [[ "$PRE_COLLECT_OS_COUNTERS" == "YES"  ]] ) ); then
        echo -e "\x1B[31m	The program iotop is not installed on this system and is required for the data collection"
        check_iotop="0"
else
        check_iotop="1"
fi

# check if sysstat is installed, we need this to capture various performance metrics from the system
check_sysstat="0"
if ( ( !( hash iostat 2>/dev/null ) || !( hash mpstat 2>/dev/null ) || !( hash pidstat 2>/dev/null ) || !( hash sar 2>/dev/null ) ) &&  ( [[ "$PRE_COLLECT_OS_COUNTERS" == "YES" ]] ) ); then
        echo -e "\x1B[31m	The program's iostat/mpstat/pidstat/sar from sysstat package is not installed on this system and is required for the data collection"
        check_sysstat="0"
else
        check_sysstat="1"
fi

# check if lsof is present and warn about it, this is used for process data collection in machine config scripts
if ( !( hash lsof 2>/dev/null ) ); then
	echo -e "\x1B[31m       The program lsof is not installed on this system and is used for the data collection, will continue without this... \x1B[0m"
fi

# now ask the user what they want to do if any program is absent
if (( ("$check_sqlcmd" == "0") || ( "$check_iotop" == "0" ) || ( "$check_sysstat" == "0" ) )); then
	echo -e "	If you do not have all the required programs installed data collection will not be reliable and complete! \x1B[0m"
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
	echo "Completed pre-req checks"
	exit 0
fi









