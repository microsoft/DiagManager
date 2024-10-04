#!/bin/bash
#Syntax:
#    machineconfig.sh  

# include helper functions
source ./pssdiag_support_functions.sh

# capture_system_info_command()
#
# Capture system information from a command
#
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


function capture_system_info()
{
    # Capture basic system information
   	#
    capture_system_info_command "Machine Name" "hostname 2>/dev/null"
	capture_system_info_command "Uptime" "uptime 2>/dev/null"
    capture_system_info_command "Kernel Version" "uname -srvimp 2>/dev/null"
    capture_system_info_command "OS release" "cat /etc/os-release 2>/dev/null"
    capture_system_info_command "Processor Information" "lscpu 2>/dev/null"
    capture_system_info_command "Processor Mapping Information" "lscpu -e 2>/dev/null"
    capture_system_info_command "Processor topology" "cat /proc/cpuinfo 2>/dev/null"
    capture_system_info_command "Free Memory" "free -m 2>/dev/null"
    capture_system_info_command "System memory information" "cat /proc/meminfo 2>/dev/null"
    capture_system_info_command "VMA max count" "cat /proc/sys/vm/max_map_count 2>/dev/null"
    [ -f /usr/sbin/dpkg ] && capture_system_info_command "System package list" "dpkg -l 2>/dev/null"
    [ -f /usr/bin/yum ] && capture_system_info_command "System package list" "yum list installed 2>/dev/null"
    capture_system_info_command "Driver List" "lsmod 2>/dev/null"
	capture_system_info_command "Sysctl kernel.sched_min_granularity_ns Related Information" "sysctl kernel.sched_min_granularity_ns 2>/dev/null"
	capture_system_info_command "Sysctl kernel.sched_wakeup_granularity_ns Related Information" "sysctl kernel.sched_wakeup_granularity_ns 2>/dev/null"
	capture_system_info_command "Sysctl vm.dirty_ratio Related Information" "sysctl vm.dirty_ratio 2>/dev/null"
	capture_system_info_command "Sysctl vm.dirty_background_ratio Related Information" "sysctl vm.dirty_background_ratio 2>/dev/null"
	capture_system_info_command "Sysctl vm.swappiness Related Information" "sysctl vm.swappiness 2>/dev/null"
	capture_system_info_command "Sysctl kernel.sched_min_granularity_ns Related Information" "sysctl kernel.sched_min_granularity_ns 2>/dev/null"
	capture_system_info_command "Sysctl kernel.numa_balancing Related Information" "sysctl kernel.numa_balancing 2>/dev/null"
	capture_system_info_command "Sysctl vm.max_map_count Related Information" "sysctl vm.max_map_count 2>/dev/null"
	capture_system_info_command "Trasparent Huge Page" "cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null"			
	capture_system_info_command "Trasparent Huge Page Defrag" "cat /sys/kernel/mm/transparent_hugepage/defrag 2>/dev/null"
	capture_system_info_command "Swap Enabled" "cat /proc/swaps 2>/dev/null" 
	capture_system_info_command "ULimits" "ulimit -a 2>/dev/null"
}

function Capture_network_info()
{
    capture_system_info_command "Netowk IP configuration" "ifconfig -a 2>/dev/null"
	capture_system_info_command "Netowk IP configuration" "ip address 2>/dev/null"
	capture_system_info_command "resolv.conf" "cat /etc/resolv.conf 2>/dev/null"
	capture_system_info_command "netstat" "netstat -anolF 2>/dev/null"
}

function capture_disk_info()
{
	capture_system_info_command "Disk Information" "lsblk -o NAME,MAJ:MIN,FSTYPE,MOUNTPOINT,PARTLABEL,SIZE,ALIGNMENT,PHY-SEC,LOG-SEC,MIN-IO,OPT-IO,ROTA,TYPE,RQ-SIZE,LABEL,MODEL,REV,VENDOR 2>/dev/null" 
	capture_system_info_command "Disk Related Information" "blockdev --report 2>/dev/null"
    capture_system_info_command "Disk Space Information" "df -TH 2>/dev/null"
	capture_system_info_command "Disk Space Information" "fdisk -l 2>/dev/null"
	capture_system_info_command "Checking Disk FUA Support" "dmesg 2>/dev/null | grep -i fua"
}


function capture_container_instance_process_info()
{
    capture_system_info_command "Command line" "cat /proc/$container_sql_child_pid/cmdline 2>/dev/null"
    capture_system_info_command "io" "cat /proc/$container_sql_child_pid/io 2>/dev/null"
    capture_system_info_command "oom_score" "cat /proc/$container_sql_child_pid/oom_score 2>/dev/null"
    capture_system_info_command "top for sql server with thread info" "top -p $container_sql_child_pid -n 1 -H 2>/dev/null"  
    capture_system_info_command "ps -u for sql server" "ps -p $container_sql_child_pid -u 2>/dev/null"
    capture_system_info_command "Process statistics" "cat /proc/$container_sql_child_pid/stat 2>/dev/null"
    capture_system_info_command "Process CGroup information" "cat /proc/$container_sql_child_pid/cgroup 2>/dev/null"
    capture_system_info_command "Process scheduler information" "cat /proc/$container_sql_child_pid/sched 2>/dev/null"
    capture_system_info_command "VMA count" "cat /proc/$container_sql_child_pid/maps 2>/dev/null | wc -l"
    capture_system_info_command "Process limits" "cat /proc/$container_sql_child_pid/limits 2>/dev/null"
    capture_system_info_command "Process status" "cat /proc/$container_sql_child_pid/status 2>/dev/null"
    capture_system_info_command "Process mounts" "cat /proc/$container_sql_child_pid/mountinfo 2>/dev/null"
    capture_system_info_command "Process handle information" "hash lsof && lsof -p $container_sql_child_pid -O -o 2>/dev/null"
}

function capture_container_instance_process_mem_map_info()
{
	capture_system_info_command "Process memory maps" "cat /proc/$container_sql_child_pid/maps 2>/dev/null"
    capture_system_info_command "Process memory maps (detailed)" "cat /proc/$container_sql_child_pid/smaps 2>/dev/null"  
}

function capture_host_instance_service_info()
{
    capture_system_info_command "Command line" "cat /proc/$pid/cmdline 2>/dev/null"
	capture_system_info_command "systemctl status" "systemctl status mssql-server.service 2>/dev/null"
	capture_system_info_command "systemctl unit" "systemctl cat mssql-server.service 2>/dev/null"
    capture_system_info_command "io" "cat /proc/$pid/io 2>/dev/null"
    capture_system_info_command "oom_score" "cat /proc/$pid/oom_score 2>/dev/null"
    capture_system_info_command "top for sql server with thread info" "top -p $pid -n 1 -H 2>/dev/null"  
    capture_system_info_command "ps -u for sql server" "ps -p $pid -u 2>/dev/null"
    capture_system_info_command "Process statistics" "cat /proc/$pid/stat 2>/dev/null"
    capture_system_info_command "Process CGroup information" "cat /proc/$pid/cgroup 2>/dev/null"
    capture_system_info_command "Process scheduler information" "cat /proc/$pid/sched 2>/dev/null"
    capture_system_info_command "VMA count" "cat /proc/$pid/maps 2>/dev/null | wc -l"
    capture_system_info_command "Process limits" "cat /proc/$pid/limits 2>/dev/null"
    capture_system_info_command "Process status" "cat /proc/$pid/status 2>/dev/null"
    capture_system_info_command "Process mounts" "cat /proc/$pid/mountinfo 2>/dev/null"
    capture_system_info_command "Process handle information" "hash lsof && lsof -p $pid -O -o 2>/dev/null"
}

function capture_host_instance_service_mem_map_info()
{
	capture_system_info_command "Process memory maps" "cat /proc/$pid/maps 2>/dev/null"
    capture_system_info_command "Process memory maps (detailed)" "cat /proc/$pid/smaps 2>/dev/null" 
}

#Starting the script

if [[ -d "$1" ]] ; then
	outputdir="$1"
else
   working_dir="$PWD"
   # Make sure log directory in working directory exists
    mkdir -p $working_dir/output

   # Define files and locations
   outputdir="$working_dir/output"
fi

pssdiag_log="$outputdir/pssdiag.log"

echo -e "$(date -u +"%T %D") Starting machineconfig log collection..." | tee -a $pssdiag_log


# Capture basic system information
infolog_filename=$outputdir/${HOSTNAME}_os_machine_config.info
echo -e "$(date -u +"%T %D") Collecting host configuration..." | tee -a $pssdiag_log
capture_system_info

#Capture Network info
infolog_filename=$outputdir/${HOSTNAME}_os_network.info
echo -e "$(date -u +"%T %D") Collecting TCP/IP information and resolv.conf..." | tee -a $pssdiag_log
Capture_network_info

# Capture Disk info
infolog_filename=$outputdir/${HOSTNAME}_os_Disk_config.info
echo -e "$(date -u +"%T %D") Collecting disk information..." | tee -a $pssdiag_log
capture_disk_info

#Capture sqlservr process info for continer instance
#find the mapping between container sql child process and local sql child process, and get its information
get_container_instance_status
if [ "${is_container_runtime_service_active}" == "YES" ]; then
    for pid in $(docker ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }'); do 
        #get container PID, this is going to be the parent local PID
        local_container_sql_Parent_pid=$(docker inspect -f '{{.State.Pid}} {{.Name}}' $pid | tr -d '/' | awk '{print $1}')
        dockername=$(docker inspect -f '{{.State.Pid}} {{.Name}}' $pid | tr -d '/' | awk '{print $2}')
        container_sql_child_pid=$(pgrep -P $local_container_sql_Parent_pid | head -n 1)
        echo -e "$(date -u +"%T %D") Collecting sqlservr process information for container instance : $dockername" | tee -a $pssdiag_log
        infolog_filename=$outputdir/${dockername}_container_instance_${container_sql_child_pid}_process.info
        capture_container_instance_process_info
    done
        for pid in $(docker ps --no-trunc | grep -e '/opt/mssql/bin/sqlservr' | awk '{ print $1 }'); do 
        #get container PID, this is going to be the parent local PID
        local_container_sql_Parent_pid=$(docker inspect -f '{{.State.Pid}} {{.Name}}' $pid | tr -d '/' | awk '{print $1}')
        dockername=$(docker inspect -f '{{.State.Pid}} {{.Name}}' $pid | tr -d '/' | awk '{print $2}')
        container_sql_child_pid=$(pgrep -P $local_container_sql_Parent_pid | head -n 1)
        echo -e "$(date -u +"%T %D") Collecting sqlservr process memory map for container instance : $dockername" | tee -a $pssdiag_log
        infolog_filename=$outputdir/${dockername}_container_instance_${container_sql_child_pid}_process_mem_map_info
        capture_container_instance_process_mem_map_info
    done
fi

#Capture sqlservr process info for host instance
get_host_instance_status
if [ "${is_host_instnace_service_active}" == "YES" ]; then
    pid=$(pgrep -P $(systemctl show --property MainPID --value mssql-server.service | head -n 1))
    echo -e "$(date -u +"%T %D") Collecting sqlservr process information for host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
    infolog_filename=$outputdir/${HOSTNAME}_host_instance_${pid}_process.info
    capture_host_instance_service_info
    echo -e "$(date -u +"%T %D") Collecting sqlservr process memory map for host instance : ${HOSTNAME}..." | tee -a $pssdiag_log
    infolog_filename=$outputdir/${HOSTNAME}_host_instance_${pid}_process.process_mem_map_info
    capture_host_instance_service_mem_map_info
fi


#Capture process list info
echo -e "$(date -u +"%T %D") Collecting process list information..." | tee -a $pssdiag_log
#ps -efaHjf >> $outputdir/${HOSTNAME}_processlist.info
ps -aux --sort -rss >> $outputdir/${HOSTNAME}_os_processlist.info

#Capture Cgroups top by memory and sql services
echo -e "$(date -u +"%T %D") Collecting CGroup top usage..." | tee -a $pssdiag_log

echo "======System totals======" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
free -h >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
echo "" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info

get_container_instance_status
if [ "${is_container_runtime_service_active}" == "YES" ]; then
    echo "======Containers instance======" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
    sudo docker stats --all --no-trunc --no-stream >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info   
    echo "" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info 
fi
get_host_instance_status
if [ "${is_host_instnace_service_active}" == "YES" ]; then
    echo "======host instance : mssql-server.service ======" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
    systemctl status mssql-server.service | head -n 11 >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
    echo "" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
fi

echo "======CGroup top======" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
echo -e "\x1B[4mControl Group                                                                                 Tasks   %CPU   Memory  Input/s Output/s\x1B[0m" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
systemd-cgtop -m -n 1 2>/dev/null >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
echo "" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info

echo "======CGroup installed======" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
grep cgroup /proc/filesystems 2>/dev/null >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
echo "" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info

echo "======top======" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
top -n 1 >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info
echo "" >> $outputdir/${HOSTNAME}_os_systemd_cgroup_top.info


