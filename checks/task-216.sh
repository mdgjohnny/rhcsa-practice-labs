#!/usr/bin/env bash
# Task: For security reasons, SSH needs to be moved to port 3333. Update the security policy to allow the SSH daemon to listen on this alternate port. The change must be persistent. (Click "Check Task" to verify)
# Title: Allow SSH Service on Port 3333
# Category: security
# Target: node1

check 'semanage port -l 2>/dev/null | grep -w "3333" | grep -q "ssh_port_t"' \
    "Port 3333/TCP is allowed for SSH services" \
    "Port 3333/TCP is not configured for SSH (hint: semanage port -l | grep ssh)"
