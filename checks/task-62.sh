#!/usr/bin/env bash
# Task: Configure Chrony to sync with hardware clock, remove other NTP sources
# Category: deploy-maintain

check \'run_ssh "$NODE1_IP" "systemctl is-active chronyd &>/dev/null"\' \
    "chronyd service is running" \
    "chronyd service is not running"

check \'run_ssh "$NODE1_IP" "grep -q "^refclock\|rtcsync" /etc/chrony.conf 2>/dev/null"\' \
    "Chrony configured for hardware clock sync" \
    "Chrony not configured for hardware clock"
