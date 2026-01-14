#!/usr/bin/env bash
# Task: Configure SSH to permit root login with password authentication.
# Title: Enable Root SSH Login
# Category: networking
# Target: node1

check 'grep -qE "^PermitRootLogin\s+(yes)" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null' \
    "PermitRootLogin is set to yes" \
    "PermitRootLogin is not enabled"

check 'grep -qE "^PasswordAuthentication\s+(yes)" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null || ! grep -qE "^PasswordAuthentication\s+no" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null' \
    "PasswordAuthentication is enabled" \
    "PasswordAuthentication is disabled"

check 'systemctl is-active sshd &>/dev/null' \
    "SSHD service is running" \
    "SSHD service is not running"
