#!/usr/bin/env bash
# Task: Set the default boot target to multi-user
# Category: operate-systems
# Target: node1

# Check default target is multi-user
check \'run_ssh "$NODE1_IP" "systemctl get-default | grep -q "multi-user.target""\' \
    "Default boot target is multi-user.target" \
    "Default boot target is not multi-user.target"
