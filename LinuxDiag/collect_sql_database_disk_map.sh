#!/bin/bash

find_sqlcmd() 
{
	SQLCMD=""
	# Try known sqlcmd paths in order
	if [ -x /opt/mssql-tools/bin/sqlcmd ]; then
		SQLCMD="/opt/mssql-tools/bin/sqlcmd"
	elif [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
		SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
	else
		SQLCMD=""
	fi
}

SQL_SERVER_NAME=${1}
CONN_AUTH_OPTIONS=${2}

QUERY=$'SET NOCOUNT ON;
SELECT d.name AS db_name, mf.physical_name
FROM sys.master_files AS mf
JOIN sys.databases AS d ON d.database_id = mf.database_id
ORDER BY d.name, mf.file_id;'

find_sqlcmd		   

# Collect data into an array
data=()
while IFS='|' read -r db_name physical_name; do


        # Initialize variables
        db_name=$(echo "$db_name" | sed 's/^ *//;s/ *$//')
        physical_name=$(echo "$physical_name" | sed 's/^ *//;s/ *$//')
        actual_path=""
        resolved=""
        FileSystem_type=""
        DpoFua_sg_modes=""
        DpoFua_sys_block=""
        diskpartition=""
        disk=""
        mount_point=""
        using_lvm=""

        # in the case there is mistmatch in case sensitivity between sys.database and actual file path, this block tries to resolve it
        if [[ ! -e "$physical_name" || "$physical_name" == "NULL" ]]; then
           
            # try1 to get directory content, and compared lowered file names. If match found, set filelocated
            # try2 to get directory content lowered, and compared lowered file names. If match found, set filelocated
            dir_path=$(dirname "$physical_name")
            file_name=$(basename "$physical_name")

            # Convert filename to lowercase
            dir_path_lower=$(echo "$dir_path" | tr '[:upper:]' '[:lower:]')
            file_name_lower=$(echo "$file_name" | tr '[:upper:]' '[:lower:]')

            # Initialize variable
            actual_path=""

            # Determine which directory to use
            if [ -d "$dir_path" ]; then
                search_dir="$dir_path"
            elif [ -d "$dir_path_lower" ]; then
                search_dir="$dir_path_lower"
            else
                actual_path=""
                resolved="Unresolved"
            fi

            # Loop through entries in the chosen directory
            while IFS= read -r entry; do
                entry_lower=$(echo "$entry" | tr '[:upper:]' '[:lower:]')
                if [ "$entry_lower" == "$file_name_lower" ]; then
                    if [[ -e "$dir_path/$entry" ]]; then
                        actual_path="$dir_path/$entry"
                        resolved="Resolved"
                    fi
                    if [[ -e "$dir_path_lower/$entry" ]]; then
                        actual_path="$dir_path_lower/$entry"
                        resolved="Resolved"
                    fi
                    break
                fi
            done < <(ls "$search_dir" 2>/dev/null)
        else
            actual_path="$physical_name"
            resolved="Exact"
        fi

        if [[ -e "$actual_path" ]]; then
            df_output=$(df -T -- "$actual_path" 2>/dev/null | awk 'NR==2')
            FileSystem_type=$(echo "$df_output" | awk '{print $2}')
            mount_point=$(echo "$df_output" | awk '{print $7}')
            #if using LVM then the mout_source will be mapper /dev/mapper/ubuntu--vg-ubuntu--lv, otherwise it will partition like /dev/sda3
            mount_source=$(findmnt -no SOURCE "$mount_point")
            Block_type=$(lsblk -no TYPE "$mount_source")

            # Check if we are using LVM, LVM means we are using disk mapper - avoid using lvs
            if [[ $Block_type == "lvm" ]]; then
                using_lvm=1
            else
                using_lvm=0
            fi
            # Only try to get diskpartition, disk and DpoFua if we have elevated permissions
            if [ "$EUID" -eq 0 ]; then
                # Get the diskpartition depending on if we are using LVM
                if [[ $using_lvm -eq 1 ]]; then
                    #if we are using LVM then use lvdisplay to get the diskpartition
                    diskpartition=$(lvdisplay -m "$mount_source" 2>/dev/null | awk '/Physical volume/ {print $3}')
                    [[ -z "$diskpartition" ]] && diskpartition="-"
                else
                    #if we are not using LVM, then its diskpartition already
                    diskpartition=$mount_source
                fi

                disk=$(echo "$diskpartition" | sed -E 's|^/dev/||; s|(nvme[0-9]+n[0-9]+)p[0-9]+|\1|; s|([a-zA-Z]+)[0-9]+|\1|')

                DpoFua_sg_modes=$(sg_modes "$diskpartition" 2>/dev/null | grep -oE 'DpoFua=[01]' | sed 's/.*=//')
                [[ -z "${DpoFua_sg_modes:-}" ]] && DpoFua_sg_modes="-"

                DpoFua_sys_block=$(cat /sys/block/$disk/queue/fua)
            fi
        fi

        data+=("$db_name|$physical_name|$actual_path|$resolved|$FileSystem_type|$DpoFua_sg_modes|$DpoFua_sys_block|$diskpartition|$disk|$mount_point|$using_lvm")

done < <("$SQLCMD" -S$SQL_SERVER_NAME $CONN_AUTH_OPTIONS -C -h -1 -W -s '|' -Q "$QUERY" | grep -v '^$')


# Define column headers dynamically
columns=("Database" "Physical_name(sys.master_files)" "Actual_Path" "Resolved Path" "Filesystem" "DpoFua(sg_modes)*" "DpoFua(/sys/block/dev/queue/fua)**" "Disk_Partition" "Disk" "Mount" "using_lvm")

# Initialize max lengths array with header lengths
declare -a max_lengths
for i in "${!columns[@]}"; do
    max_lengths[$i]=${#columns[$i]}
done

# Calculate max length for each column dynamically
for row in "${data[@]}"; do
    IFS='|' read -r -a fields <<< "$row"
    for i in "${!fields[@]}"; do
        (( ${#fields[$i]} > max_lengths[$i] )) && max_lengths[$i]=${#fields[$i]}
    done
done

# Print header dynamically
for i in "${!columns[@]}"; do
    printf "%-${max_lengths[$i]}s " "${columns[$i]}"
done
echo

# Print separator
total_width=0
for len in "${max_lengths[@]}"; do
    total_width=$((total_width + len + 1))
done
printf '%*s\n' "$total_width" '' | tr ' ' '-'

# Print rows dynamically
for row in "${data[@]}"; do
    IFS='|' read -r -a fields <<< "$row"
    for i in "${!fields[@]}"; do
        printf "%-${max_lengths[$i]}s " "${fields[$i]}"
    done
    echo
done

# Print footer
printf "\n"
printf "Legend:\n"
printf "DpoFua(sg_modes)*: Indicates whether the device reports support for Force Unit Access (FUA)\n"
printf "DpoFua(/sys/block/dev/queue/fua)**: Indicates whether the kernel driver has enabled Force Unit Access (FUA) on the device\n\n"
printf "If you notice any discrepancies in FUA reporting between DpoFua(sg_modes) and DpoFua(/sys/block/dev/queue/fua), run \"dmesg | grep -i fua\" to check if FUA was disabled by kernel driver and why. If this is an Azure VM, verify whether read/write disk caching is enabled.\n\n"
printf "Unresolved path indicates that the file does not exist or there is a case sensitivity mismatch between the actual physical file path and the Physical_name column value in sys.master_files. \n"
printf "Empty fields indicate the script was run without elevated (sudo) permissions. \n"

exit 0