#!/usr/bin/env bash
# Task: Verify root SSH access to node2
# Title: Verify SSH Access (node2)
# Category: essential-tools

# Try hostname first, fall back to IP
if run_ssh "$NODE2" exit &>/dev/null; then
    RETURN_STATUS=0
    SSH_TARGET="$NODE2"
elif run_ssh "$NODE2_IP" exit &>/dev/null; then
    RETURN_STATUS=0
    SSH_TARGET="$NODE2_IP"
else
    RETURN_STATUS=1
    SSH_TARGET="$NODE2 / $NODE2_IP"
fi

check '[[ "$RETURN_STATUS" -eq 0 ]]' \
    "Can SSH as root into node2 ($SSH_TARGET)" \
    "Cannot SSH as root into node2 ($SSH_TARGET)"
