#!/usr/bin/env bash
# Task: Configure chronyd with server time.google.com using the iburst option for faster initial sync.
# Title: Configure Chrony with iburst
# Category: deploy-maintain
# Target: node1

check 'grep -qE "^server.*time\.google\.com.*iburst" /etc/chrony.conf 2>/dev/null' \
    "time.google.com configured with iburst" \
    "time.google.com with iburst not found"

check 'systemctl is-active chronyd &>/dev/null' \
    "chronyd is running" \
    "chronyd is not running"
