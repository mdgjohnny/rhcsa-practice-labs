#!/usr/bin/env bash
# Task: On rhcsa2 - yes-no.sh script
# "yes" -> "that's nice", "no" -> "I am sorry", else -> "unknown argument"

# Check if script exists
check 'ssh "$NODE2_IP" "[[ -x /root/yes-no.sh ]] || [[ -x /usr/local/bin/yes-no.sh ]]" 2>/dev/null' \
    "yes-no.sh script exists on node2" \
    "yes-no.sh script not found"
