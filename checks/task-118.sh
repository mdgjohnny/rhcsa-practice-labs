#!/usr/bin/env bash
# Task: Configure SSH server security: disable root password login (permit key-based only), disable empty passwords, set max authentication attempts to 3, and set login grace time to 60 seconds.
# Title: Harden SSH Server Configuration
# Category: networking
# Target: node1

check 'systemctl is-active sshd &>/dev/null' \
    "SSH server is running" \
    "SSH server is not running"

check 'grep -qE "^PermitRootLogin\s+(prohibit-password|without-password)" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null' \
    "Root login limited to key-based" \
    "PermitRootLogin not set to prohibit-password"

check 'grep -qE "^PermitEmptyPasswords\s+no" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null' \
    "Empty passwords disabled" \
    "PermitEmptyPasswords not set to no"

check 'grep -qE "^MaxAuthTries\s+3" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null' \
    "MaxAuthTries set to 3" \
    "MaxAuthTries not configured"

check 'grep -qE "^LoginGraceTime\s+60" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null' \
    "LoginGraceTime set to 60" \
    "LoginGraceTime not configured"
