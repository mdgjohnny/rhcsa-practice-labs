#!/usr/bin/env bash
# Task: Configure chronyd to synchronize time with the NTP server pool.ntp.org. Ensure the service starts on boot.
# Title: Configure Chrony NTP Client
# Category: deploy-maintain
# Target: node1

check 'systemctl is-enabled chronyd &>/dev/null' \
    "chronyd is enabled to start on boot" \
    "chronyd is not enabled"

check 'systemctl is-active chronyd &>/dev/null' \
    "chronyd service is running" \
    "chronyd service is not running"

check 'grep -qE "^(server|pool).*pool\.ntp\.org" /etc/chrony.conf 2>/dev/null' \
    "pool.ntp.org configured in /etc/chrony.conf" \
    "pool.ntp.org not found in chrony.conf"
