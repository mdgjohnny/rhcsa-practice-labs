#!/usr/bin/env bash
# Task: Ensure that both nodes support graphical applications through the SSH session
# Category: networking
# Target: both

# Check if X11 forwarding is enabled in sshd_config
check \'run_ssh "$NODE1_IP" "grep -q "^X11Forwarding yes" /etc/ssh/sshd_config"\' \
    "X11Forwarding is enabled in sshd_config" \
    "X11Forwarding is not enabled"

# Check if xauth is installed
check 'command -v xauth &>/dev/null' \
    "xauth is installed" \
    "xauth is not installed"
