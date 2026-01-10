#!/usr/bin/env bash
# Task: Configure SSH server with required security settings as specified in the task requirements.
# Title: Configure SSH Server
# Category: networking
# Target: node1

# Check SSH service is running
check 'systemctl is-active sshd &>/dev/null' \
    "SSH server is running" \
    "SSH server is not running"

# Check SSH is enabled at boot
check 'systemctl is-enabled sshd &>/dev/null' \
    "SSH server is enabled at boot" \
    "SSH server is not enabled"
