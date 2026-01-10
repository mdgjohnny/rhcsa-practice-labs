#!/usr/bin/env bash
# Task: Configure SSH to support X11 forwarding for graphical applications.
# Title: Enable SSH X11 Forwarding
# Category: networking
# Target: both

# Check if X11 forwarding is enabled in sshd_config
check 'grep -q "^X11Forwarding yes" /etc/ssh/sshd_config' \
    "X11Forwarding is enabled in sshd_config" \
    "X11Forwarding is not enabled"

# Check if xauth is installed
check 'command -v xauth &>/dev/null' \
    "xauth is installed" \
    "xauth is not installed"
