#!/usr/bin/env bash
# Task: Add custom message to /var/log/messages, output to /root/customlogmessage
# Title: Add Custom Log Message
# Category: operate-systems
# Target: node2

check '[[ -f /root/customlogmessage ]]' \
    "File /root/customlogmessage exists" \
    "File /root/customlogmessage does not exist"

check 'grep -q "RHCSA sample exam" /root/customlogmessage 2>/dev/null' \
    "Custom log message captured in output" \
    "Custom log message not found in output"
