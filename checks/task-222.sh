#!/usr/bin/env bash
# Task: The SSH daemon has been configured to also listen on port 2222 (check /etc/ssh/sshd_config), but it's not working on that port. The configuration syntax is correct. Fix the issue so sshd can bind to port 2222. The service should be restarted after fixing.
# Title: Enable SSH on Alternate Port (SELinux)
# Category: security
# Target: node1

check 'semanage port -l 2>/dev/null | grep ssh_port_t | grep -q "2222"' \
    "Port 2222 is allowed for SSH in SELinux policy" \
    "Port 2222 not in SELinux ssh_port_t (use semanage port)"

check 'ss -tlnp 2>/dev/null | grep -q ":2222"' \
    "Something is listening on port 2222" \
    "Nothing listening on port 2222 - restart sshd after SELinux fix"

check 'systemctl is-active sshd &>/dev/null' \
    "SSH service is running" \
    "SSH service not running"
