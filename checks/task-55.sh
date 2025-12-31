#!/usr/bin/env bash
# Task: On rhcsa2 - Determine and apply recommended tuned profile

check 'ssh "$NODE2_IP" "systemctl is-active tuned &>/dev/null" 2>/dev/null' \
    "tuned service is running on node2" \
    "tuned service is not running on node2"

check 'ssh "$NODE2_IP" "tuned-adm active &>/dev/null" 2>/dev/null' \
    "A tuned profile is active on node2" \
    "No tuned profile is active on node2"
