#!/bin/bash

# this script checks if the required programs and packages are present on this system
# if any programs are not present then we cannot guarantee the reliability and usefullness of the data collection

# storing the status of the program install in local variables, 0 means program absent, 1 means program present
# if you add any new commands or programs in the data collection, make sure to add a check here

echo "Starting pre-req checks"

# first we check if there is another pssdiag running
anchor_check=`ps aux | grep -i "pssdiag_anchor.sh" | grep -v "grep" | wc -l`
if (( "$anchor_check" >= 1 ))
	then
		echo "PSSDIAG is already running on this system. Only one instance of PSSDIAG is allowed to execute."
		exit 1
	else
		# we are good to continue
		sleep 0s
fi

# check if sqlcmd is installed, we need this to execute TSQL scripts
check_sqlcmd="0"
if !( hash /opt/mssql-tools/bin/sqlcmd 2>/dev/null ); then
	echo "  The program sqlcmd from mssql-tools package is not installed on this system"
	check_sqlcmd="0"
else
	check_sqlcmd="1"
fi

# check if iotop is installed, we need this to capture io related metrics from the system
check_iotop="0"
if !( hash iotop 2>/dev/null ); then
        echo "  The program iotop is not installed on this system"
        check_iotop="0"
else
        check_iotop="1"
fi

# check if sysstat is installed, we need this to capture various performance metrics from the system
check_sysstat="0"
if ( !( hash iostat 2>/dev/null ) || !( hash mpstat 2>/dev/null ) || !( hash pidstat 2>/dev/null ) || !( hash sar 2>/dev/null ) ); then
        echo "  The program's iostat/mpstat/pidstat/sar from sysstat package is not installed on this system"
        check_sysstat="0"
else
        check_sysstat="1"
fi

# now ask the user what they want to do if any program is absent
if (( ("$check_sqlcmd" == "0") || ( "$check_iotop" == "0" ) || ( "$check_sysstat" == "0" ) )); then
	echo "  If you do not have all the required programs installed data collection will not be reliable and complete!"
	read -p "  Do you want to continue with data collection? Type Y or N : " check_input
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









