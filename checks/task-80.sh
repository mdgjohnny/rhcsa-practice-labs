#!/usr/bin/env bash
# Task: Set system to boot to text mode (multi-user target). Ensure tty6 returns to text mode.
# Title: Disable Graphical Interface
# Category: operate-systems
# Target: node1

# Check if default target is multi-user (text mode)
check 'systemctl get-default | grep -q "multi-user.target"' \
    "Default target is multi-user.target (text mode)" \
    "Default target is not multi-user.target"

# Check if graphical target is not active by default
check '! systemctl is-active graphical.target &>/dev/null || systemctl get-default | grep -q multi-user' \
    "System boots to text mode" \
    "System may still boot to graphical mode"
