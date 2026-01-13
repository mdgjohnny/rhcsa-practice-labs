#!/usr/bin/env bash
# Task: Verify that chronyd is synchronized with an NTP source using chronyc. The system should show as synchronized.
# Title: Verify Chrony Sync Status
# Category: deploy-maintain
# Target: node1

check 'systemctl is-active chronyd &>/dev/null' \
    "chronyd is running" \
    "chronyd is not running"

check 'chronyc tracking 2>/dev/null | grep -qiE "Leap status.*Normal|Reference ID.*[0-9]"' \
    "chronyd is tracking time source" \
    "chronyd is not synchronized"

check 'timedatectl show 2>/dev/null | grep -q "NTPSynchronized=yes" || timedatectl status 2>/dev/null | grep -qi "synchronized: yes"' \
    "System clock is NTP synchronized" \
    "System clock not synchronized"
