#!/usr/bin/env bash
# Task: Start the tuned service, determine the recommended profile using "tuned-adm recommend", and apply it.
# Title: Apply Recommended Tuned Profile
# Category: operate-systems
# Target: node2

check 'systemctl is-active tuned &>/dev/null' \
    "tuned service is running" \
    "tuned service is not running"

check 'tuned-adm active 2>/dev/null | grep -qE "Current active profile:"' \
    "A tuned profile is active" \
    "No tuned profile is active"

# The active profile should match the recommended one
check '[[ "$(tuned-adm active 2>/dev/null | grep -oP "Current active profile: \K.*")" == "$(tuned-adm recommend 2>/dev/null)" ]]' \
    "Active profile matches recommended" \
    "Active profile doesn't match recommended"
