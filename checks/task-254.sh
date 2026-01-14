#!/usr/bin/env bash
# Task: Create /root/proclist.sh that lists the top 5 CPU-consuming processes using ps, showing PID, user, CPU%, and command name.
# Title: Shell Script - Process List
# Category: shell-scripts
# Target: node1

check '[[ -x /root/proclist.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "ps " /root/proclist.sh' \
    "Script uses ps command" \
    "Script doesn't use ps command"

check 'grep -qE "head|tail|-[0-9]+|sort" /root/proclist.sh' \
    "Script limits or sorts output" \
    "Script doesn't limit/sort output"

check '/root/proclist.sh 2>/dev/null | head -6 | grep -qE "[0-9]+.*[0-9.]+"' \
    "Output contains process info with numbers" \
    "Output doesn't look like process listing"
