#!/usr/bin/env bash
# Task: On rhcsa2 - Find files modified in last 30 days, save to /var/tmp/modfiles.txt

check 'run_ssh "$NODE2_IP" "[[ -f /var/tmp/modfiles.txt ]]" 2>/dev/null' \
    "File /var/tmp/modfiles.txt exists on node2" \
    "File /var/tmp/modfiles.txt does not exist"

check 'run_ssh "$NODE2_IP" "[[ -s /var/tmp/modfiles.txt ]]" 2>/dev/null' \
    "/var/tmp/modfiles.txt is not empty" \
    "/var/tmp/modfiles.txt is empty"
