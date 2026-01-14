#!/usr/bin/env bash
# Task: Use the logger command to send a message "RHCSA practice task completed" to the system log. Then find that message in the logs and save the log line to /root/customlogmessage.
# Title: Log Custom Message with Logger
# Category: operate-systems
# Target: node2

check '[[ -f /root/customlogmessage ]]' \
    "File /root/customlogmessage exists" \
    "File /root/customlogmessage does not exist"

check '[[ -s /root/customlogmessage ]]' \
    "File has content" \
    "File is empty"

check 'grep -qi "RHCSA\|practice\|task\|completed" /root/customlogmessage 2>/dev/null' \
    "Log message found in file" \
    "Expected log message not in file"
