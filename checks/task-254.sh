#!/usr/bin/env bash
# Task: Create /root/proclist.sh that lists top 5 CPU-consuming processes using ps and outputs formatted results.
# Title: Shell Script - Process List
# Category: shell-scripts
# Target: node1

check '[[ -x /root/proclist.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "ps |top " /root/proclist.sh' \
    "Script uses ps or top" \
    "No process command found"

check '[[ $(/root/proclist.sh 2>/dev/null | wc -l) -ge 5 ]]' \
    "Script outputs at least 5 lines" \
    "Not enough output lines"
