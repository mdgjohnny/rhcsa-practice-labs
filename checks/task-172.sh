#!/usr/bin/env bash
# Task: Synchronize /var/log from rhcsa2 to /root/remote-logs/ on this system. Preserve permissions during the transfer.
# Title: Synchronize Directory from Remote
# Category: networking
# Target: node1

check '[[ -d /root/remote-logs ]]' \
    "Directory /root/remote-logs exists" \
    "Directory /root/remote-logs not found"

check '[[ -f /root/remote-logs/messages ]] || [[ -f /root/remote-logs/secure ]] || ls /root/remote-logs/*.log &>/dev/null' \
    "Log files present in /root/remote-logs" \
    "No log files found"

check '[[ $(ls -A /root/remote-logs/ 2>/dev/null | wc -l) -gt 2 ]]' \
    "Multiple files synchronized" \
    "Insufficient files synchronized"
