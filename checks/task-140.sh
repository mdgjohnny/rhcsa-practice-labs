#!/usr/bin/env bash
# Task: Set default boot target to multi-user
# Title: Set Boot Target (multi-user)
# Category: operate-systems
# Target: node1

# Check default target is multi-user
check 'systemctl get-default | grep -q "multi-user.target"' \
    "Default boot target is multi-user.target" \
    "Default boot target is not multi-user.target"
