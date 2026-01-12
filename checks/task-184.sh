#!/usr/bin/env bash
# Task: A process "sleep 7200" is running. Change its nice value to 15 using renice. The process should continue running with the new priority.
# Title: Change Running Process Priority
# Category: operate-systems
# Target: node1
# Setup: nice -n 0 sleep 7200 &

check 'pgrep -f "sleep 7200" >/dev/null' \
    "Sleep 7200 process is running" \
    "Sleep 7200 process not found"

check 'pid=$(pgrep -f "sleep 7200" | head -1); [[ $(ps -o ni= -p $pid | tr -d " ") == "15" ]]' \
    "Process has nice value of 15" \
    "Process nice value is not 15 (use renice to change)"
