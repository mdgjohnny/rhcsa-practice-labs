#!/usr/bin/env bash
# Task: Use the logger command to send a message "RHCSA practice task completed" to the system log. Then find that message using grep (e.g., in /var/log/messages or via journalctl) and save the matching log line to /root/customlogmessage.
# Title: Log Custom Message with Logger
# Category: operate-systems
# Target: node1

check 'grep -qF "RHCSA practice task completed" /var/log/messages 2>/dev/null || journalctl 2>/dev/null | grep -qF "RHCSA practice task completed"' \
    "Message found in system log (was logger actually used?)" \
    "Message not found in system log - use logger to send it first"

check '[[ -f /root/customlogmessage ]]' \
    "File /root/customlogmessage exists" \
    "File /root/customlogmessage does not exist"

check '[[ -s /root/customlogmessage ]]' \
    "File has content" \
    "File is empty"

check 'line=$(cat /root/customlogmessage 2>/dev/null); [[ -n "$line" ]] && (grep -qF "$line" /var/log/messages 2>/dev/null || journalctl 2>/dev/null | grep -qF "$line")' \
    "Saved content is a genuine line copied from the system log" \
    "Saved content does not match an actual line in the system log (don't just type the message into the file - grep it out of /var/log/messages or journalctl)"
