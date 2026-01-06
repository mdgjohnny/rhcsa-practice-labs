#!/usr/bin/env bash
# Task: Ensure that `node1` does not show a graphical interface anymore, but just a text-based login prompt. From tty6, switch back to the graphical interface
# Category: operate-systems
# Target: node1

# Check if default target is multi-user (text mode)
check \'run_ssh "$NODE1_IP" "systemctl get-default | grep -q "multi-user.target""\' \
    "Default target is multi-user.target (text mode)" \
    "Default target is not multi-user.target"

# Check if graphical target is not active by default
check '! systemctl is-active graphical.target &>/dev/null || systemctl get-default | grep -q multi-user' \
    "System boots to text mode" \
    "System may still boot to graphical mode"
