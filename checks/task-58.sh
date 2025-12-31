#!/usr/bin/env bash
# Task: On rhcsa2 - Script prints RHCSA when RHCE passed, and vice versa
# Usage message with exit 5 if no argument

# Test existence of script
check 'ssh "$NODE2_IP" "[[ -x /root/rhcsa-rhce.sh ]] || [[ -x /usr/local/bin/rhcsa-rhce.sh ]]" 2>/dev/null' \
    "Script exists and is executable on node2" \
    "Script not found or not executable"
