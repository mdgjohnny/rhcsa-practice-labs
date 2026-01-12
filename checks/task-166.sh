#!/usr/bin/env bash
# Task: Start a background process "sleep 3600" with a nice value of 10 (lower priority). The process should be running with the adjusted priority.
# Title: Adjust Process Priority with Nice
# Category: operate-systems
# Target: node1

check 'pgrep -f "sleep 3600" >/dev/null' \
    "Sleep 3600 process is running" \
    "Sleep 3600 process not found (start with: nice -n 10 sleep 3600 &)"

check 'ps -o ni= -p $(pgrep -f "sleep 3600" | head -1) 2>/dev/null | grep -qE "^\s*10\s*$"' \
    "Process has nice value of 10" \
    "Process nice value is not 10"
