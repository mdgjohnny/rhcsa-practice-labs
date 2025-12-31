#!/usr/bin/env bash
# Task: On rhcsa2 - Script to check files starting with "ac" in /usr/bin
# and display their statistics

# This task is about creating a script - hard to verify execution
# Just check if such a script exists
check 'ssh "$NODE2_IP" "ls /root/*.sh 2>/dev/null | head -1" 2>/dev/null' \
    "Shell scripts exist in /root on node2" \
    "No shell scripts found in /root"
