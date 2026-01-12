#!/usr/bin/env bash
# Task: Create a symbolic link /opt/logs that points to /var/log. Verify you can access log files through this link.
# Title: Create Directory Symbolic Link
# Category: essential-tools
# Target: node1

check '[[ -L /opt/logs ]]' \
    "Symbolic link /opt/logs exists" \
    "Symbolic link /opt/logs not found"

check '[[ $(readlink /opt/logs) == "/var/log" ]]' \
    "Link points to /var/log" \
    "Link does not point to /var/log"

check 'ls /opt/logs/messages 2>/dev/null || ls /opt/logs/secure 2>/dev/null || ls /opt/logs/*.log 2>/dev/null' \
    "Link is functional (can list files through it)" \
    "Link is broken or directory not accessible"
