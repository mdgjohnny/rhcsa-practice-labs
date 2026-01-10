#!/usr/bin/env bash
# Task: Determine the recommended tuned profile for this system and apply it.
# Title: Apply Tuned Profile
# Category: operate-systems
# Target: node2

check 'systemctl is-active tuned &>/dev/null' \
    "tuned service is running" \
    "tuned service is not running"

check 'tuned-adm active &>/dev/null' \
    "A tuned profile is active" \
    "No tuned profile is active"
