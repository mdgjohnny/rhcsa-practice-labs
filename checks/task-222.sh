#!/usr/bin/env bash
# Task: SSH is configured to use port 2222 but fails to start. Diagnose and fix the SELinux issue.
# Title: Fix SELinux SSH Port Issue
# Category: security
# Target: node1

check 'semanage port -l 2>/dev/null | grep ssh_port_t | grep -q 2222' \
    "Port 2222 is allowed for SSH in SELinux" \
    "Port 2222 not in ssh_port_t"
