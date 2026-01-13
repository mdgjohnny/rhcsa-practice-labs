#!/usr/bin/env bash
# Task: Configure chronyd with two NTP servers: time1.google.com (preferred) and time2.google.com. Use the prefer option on the first server.
# Title: Configure Chrony Multiple Servers
# Category: deploy-maintain
# Target: node1

check 'grep -qE "^server.*time1\.google\.com.*prefer" /etc/chrony.conf 2>/dev/null' \
    "time1.google.com configured with prefer" \
    "time1.google.com with prefer not found"

check 'grep -qE "^server.*time2\.google\.com" /etc/chrony.conf 2>/dev/null' \
    "time2.google.com configured" \
    "time2.google.com not found"

check 'systemctl is-active chronyd &>/dev/null' \
    "chronyd is running" \
    "chronyd is not running"
