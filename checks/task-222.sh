#!/usr/bin/env bash
# Task: The SSH daemon has been configured to listen on port 2222 (check /etc/ssh/sshd_config), but the service fails to start. The configuration syntax is correct. Diagnose and fix the issue so sshd can bind to port 2222. (Click "Check Task" to set up the scenario)
# Title: Fix SSH on Alternate Port
# Category: security
# Target: node1

# Setup: Configure sshd for port 2222
if ! grep -q "^Port 2222" /etc/ssh/sshd_config 2>/dev/null; then
    # Add Port 2222 (keep 22 as well for safety)
    sed -i '/^#Port 22/a Port 2222' /etc/ssh/sshd_config 2>/dev/null || \
    echo "Port 2222" >> /etc/ssh/sshd_config
fi

# THE CHECKS
check 'semanage port -l 2>/dev/null | grep ssh_port_t | grep -q "2222"' \
    "Port 2222 is allowed for SSH in security policy" \
    "Port 2222 not allowed for SSH (hint: check why sshd can't bind)"

check 'ss -tlnp 2>/dev/null | grep -q ":2222 " || systemctl is-active sshd &>/dev/null' \
    "SSH service is functional" \
    "SSH service not running properly"
