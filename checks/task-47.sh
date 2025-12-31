#!/usr/bin/env bash
# Task: On rhcsa2 - Add custom message to /var/log/messages
# Confirm with regex, output to /root/customlogmessage

check 'run_ssh "$NODE2_IP" "[[ -f /root/customlogmessage ]]" 2>/dev/null' \
    "File /root/customlogmessage exists on node2" \
    "File /root/customlogmessage does not exist"

check 'run_ssh "$NODE2_IP" "grep -q \"RHCSA sample exam\" /root/customlogmessage 2>/dev/null"' \
    "Custom log message captured in output" \
    "Custom log message not found in output"
