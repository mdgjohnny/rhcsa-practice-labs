#!/usr/bin/env bash
# Task: Set default boot target to multi-user.target on both VMs
# Category: deploy-maintain
# Target: both

check 'run_ssh "$NODE1_IP" "systemctl get-default" 2>/dev/null | grep -q "multi-user.target"' \
    "Node1: default target is multi-user.target" \
    "Node1: default target is not multi-user.target"

check 'run_ssh "$NODE2_IP" "systemctl get-default" 2>/dev/null | grep -q "multi-user.target"' \
    "Node2: default target is multi-user.target" \
    "Node2: default target is not multi-user.target"
