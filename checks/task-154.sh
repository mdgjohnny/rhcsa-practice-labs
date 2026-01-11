#!/usr/bin/env bash
# Task: Log message "This is RHCSA sample exam on <date> by <user>" to /var/log/messages.
# Title: Log Custom Message
# Category: operate-systems
# Target: node1

check 'grep -q "RHCSA sample exam" /var/log/messages 2>/dev/null' \
    "RHCSA sample exam message found in /var/log/messages" \
    "RHCSA sample exam message not found"
