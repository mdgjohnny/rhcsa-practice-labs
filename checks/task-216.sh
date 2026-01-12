#!/usr/bin/env bash
# Task: Add port 3333/TCP to the SELinux ssh_port_t type to allow SSH on that alternate port.
# Title: Add SSH SELinux Port
# Category: security
# Target: node1

check 'semanage port -l 2>/dev/null | grep ssh_port_t | grep -q 3333' \
    "Port 3333 is assigned to ssh_port_t" \
    "Port 3333 not in ssh_port_t"
