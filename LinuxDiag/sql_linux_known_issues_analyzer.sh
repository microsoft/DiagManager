#!/usr/bin/env bash
# =============================================================================
# SQL on Linux known issues analyzer  (READ-ONLY)
#
# This script DOES NOT modify the system.
# VERSION="1.0 (2025-09-01)"
# =============================================================================

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


TITLE="SQL on Linux known issues analyzer"
VERSION="1.0 Beta"

SQL_SERVER_NAME=${1}
CONN_AUTH_OPTIONS=${2}

knownIssuesCount=0

find_sqlcmd

# -----------------------------------------------------------------------------
# Environment discovery
# -----------------------------------------------------------------------------
echo "=== $TITLE v$VERSION ==="
date

# =============================================================================
# Issue 1: Non-yielding scheduler 
# Conditions:
#  - TF 3979 is not enabled 
#  - Replication is enabled
# Solution:
#  - Enable TF 3979 or Disable replication
# =============================================================================

# Path to the configuration file
CONF_FILE="/var/opt/mssql/mssql.conf"

# Initialize the variable
Condition1_Replication=99
Condition2_tf3979=99
REPL_QUERY=$'SET NOCOUNT ON;select 1 from sys.databases where is_published = 1 or is_subscribed = 1 or is_merge_published = 1 or is_distributor = 1'

# Validate Condition 1
if [[ $("$SQLCMD" -S"$SQL_SERVER_NAME" $CONN_AUTH_OPTIONS -C -h -1 -W -Q "${REPL_QUERY}") == 1 ]]; then
    Condition1_Replication=1
else
    Condition1_Replication=0
fi

# Validate Condition 2
if [[ -f "$CONF_FILE" ]]; then
    # Search for traceflag entries with value 3979
    if grep -E "traceflag[0-9]+ *= *3979" "$CONF_FILE" > /dev/null; then
        Condition2_tf3979=1
    else
        Condition2_tf3979=0
    fi
fi

#Validate all Conditions, and report if they all met.
if [[ $Condition1_Replication -eq 1 && $Condition2_tf3979 -eq 0 ]]; then
    knownIssuesCount=$((knownIssuesCount + 1))
    echo "============================================================================================================================================"
    echo "⚠️  Known Issue Identified"
    echo "============================================================================================================================================"
    echo ""
    echo "Condition1: Replication is enabled"
    echo "Condition2: Trace Flag 3979 is NOT enabled"
    echo "Applies to: SQL on Linux"
    echo ""
    echo "The current configuration may lead to a non-yielding scheduler caused by spinlock contention in the log manager."
    echo ""
    echo "💡 Recommended Actions:"
    echo "   - ✅ Enable Trace Flag 3979, however, before enabling this trace flag, make sure that the IO Path supports FUA"
    echo "   - OR"
    echo "   - ❎ Disable Replication"
    echo ""
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo -e "\n=== Analysis complete ==="
echo "Total Known Issues Identified: $knownIssuesCount"

