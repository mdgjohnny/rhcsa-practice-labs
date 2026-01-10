#!/usr/bin/env bash
# Task: Configure SSH: allow root login, change port to 2022.
# Title: Configure SSH
# Category: security
# Target: node2

check 'grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config' \
    "Root login is permitted" \
    "Root login is not permitted"

check 'grep -q "^Port 2022" /etc/ssh/sshd_config' \
    "SSH port 2022 configured" \
    "SSH port 2022 not configured"

check 'ss -tlnp | grep -q :2022' \
    "SSH listening on port 2022" \
    "SSH not listening on port 2022"
