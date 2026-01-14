#!/usr/bin/env bash
# Task: Configure rhcsa2 as an NTP server that allows clients from the local network to sync time. The chronyd service should be running and enabled.
# Title: Configure Chrony NTP Server
# Category: deploy-maintain
# Target: node2

check 'systemctl is-enabled chronyd &>/dev/null' \
    "chronyd is enabled" \
    "chronyd is not enabled"

check 'systemctl is-active chronyd &>/dev/null' \
    "chronyd service is running" \
    "chronyd service is not running"

# Check for allow directive permitting clients
check 'grep -qE "^allow" /etc/chrony.conf 2>/dev/null' \
    "Chrony configured to allow clients" \
    "No 'allow' directive in chrony.conf"
