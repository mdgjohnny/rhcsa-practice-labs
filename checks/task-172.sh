#!/usr/bin/env bash
# Task: Use rsync to synchronize /var/log from rhcsa2 to /root/remote-logs/ on this system. Preserve permissions and use compression during transfer.
# Title: Rsync from Remote System
# Category: operate-systems
# Target: node1

check '[[ -d /root/remote-logs ]]' \
    "Directory /root/remote-logs exists" \
    "Directory /root/remote-logs not found"

check 'ls /root/remote-logs/*.log 2>/dev/null || ls /root/remote-logs/messages 2>/dev/null || ls /root/remote-logs/secure 2>/dev/null' \
    "Log files present in /root/remote-logs" \
    "No log files found in /root/remote-logs"

check '[[ $(ls -la /root/remote-logs/ 2>/dev/null | wc -l) -gt 3 ]]' \
    "Multiple files synchronized" \
    "Insufficient files synchronized"
