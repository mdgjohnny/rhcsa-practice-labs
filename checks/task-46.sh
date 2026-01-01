#!/usr/bin/env bash
# Task: On rhcsa2 - Enable atd for user20, deny for user30
# Category: deploy-maintain

check 'run_ssh "$NODE2_IP" "grep -q user20 /etc/at.allow 2>/dev/null"' \
    "user20 is in /etc/at.allow on node2" \
    "user20 is not in /etc/at.allow"

check 'run_ssh "$NODE2_IP" "grep -q user30 /etc/at.deny 2>/dev/null"' \
    "user30 is in /etc/at.deny on node2" \
    "user30 is not in /etc/at.deny"
