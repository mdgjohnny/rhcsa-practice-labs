#!/usr/bin/env bash
# Task: Configure an SSH server that meets the following requirements
# Category: networking
# Target: node1

# Check SSH service is running
check \'run_ssh "$NODE1_IP" "systemctl is-active sshd &>/dev/null"\' \
    "SSH server is running" \
    "SSH server is not running"

# Check SSH is enabled at boot
check \'run_ssh "$NODE1_IP" "systemctl is-enabled sshd &>/dev/null"\' \
    "SSH server is enabled at boot" \
    "SSH server is not enabled"
