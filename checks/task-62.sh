#!/usr/bin/env bash
# Task: Configure Chrony to synchronize with a custom NTP server: pool.ntp.org. Ensure the chronyd service is running and enabled.
# Title: Configure Chrony NTP Client
# Category: deploy-maintain
# Target: node1

check 'systemctl is-active chronyd &>/dev/null' \
    "chronyd service is running" \
    "chronyd service is not running"

check 'systemctl is-enabled chronyd &>/dev/null' \
    "chronyd service is enabled" \
    "chronyd service is not enabled"

check 'grep -qE "^(server|pool).*pool\.ntp\.org" /etc/chrony.conf 2>/dev/null' \
    "pool.ntp.org configured in chrony.conf" \
    "pool.ntp.org not found in chrony.conf"
