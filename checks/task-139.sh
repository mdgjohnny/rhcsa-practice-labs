#!/usr/bin/env bash
# Task: Using a manual method , set the system hostname to rhcsa1.example.com and alias rhcsa1. Make sure that the new hostname is reflected in the command prompt
# Category: networking
# Target: node1

# Check hostname is set
check \'run_ssh "$NODE1_IP" "hostnamectl --static 2>/dev/null | grep -q "rhcsa1.example.com" || hostname | grep -q "rhcsa1""\' \
    "Hostname is set to rhcsa1.example.com" \
    "Hostname is not set correctly"

# Check /etc/hostname
check \'run_ssh "$NODE1_IP" "cat /etc/hostname 2>/dev/null | grep -q "rhcsa1""\' \
    "Hostname is persistent in /etc/hostname" \
    "Hostname not in /etc/hostname"

# Check /etc/hosts has alias
check \'run_ssh "$NODE1_IP" "grep -q "rhcsa1" /etc/hosts"\' \
    "rhcsa1 alias exists in /etc/hosts" \
    "rhcsa1 alias not in /etc/hosts"
