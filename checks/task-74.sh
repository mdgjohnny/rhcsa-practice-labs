#!/usr/bin/env bash
# Task: On rhcsa2 - SSH config: allow root, port 2022
# Category: security

check 'run_ssh "$NODE2_IP" "grep -q \"^PermitRootLogin yes\" /etc/ssh/sshd_config"' \
    "Root login is permitted on node2" \
    "Root login is not permitted on node2"

check 'run_ssh "$NODE2_IP" "grep -q \"^Port 2022\" /etc/ssh/sshd_config"' \
    "SSH port 2022 configured on node2" \
    "SSH port 2022 not configured on node2"

check 'run_ssh "$NODE2_IP" "ss -tlnp | grep -q :2022"' \
    "SSH listening on port 2022 on node2" \
    "SSH not listening on port 2022"
