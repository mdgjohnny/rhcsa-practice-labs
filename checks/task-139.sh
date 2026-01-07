#!/usr/bin/env bash
# Task: Set hostname to rhcsa1.example.com with alias rhcsa1
# Title: Set FQDN Hostname
# Category: networking
# Target: node1

# Check hostname is set
check 'hostnamectl --static 2>/dev/null | grep -q "rhcsa1.example.com" || hostname | grep -q "rhcsa1"' \
    "Hostname is set to rhcsa1.example.com" \
    "Hostname is not set correctly"

# Check /etc/hostname
check 'cat /etc/hostname 2>/dev/null | grep -q "rhcsa1"' \
    "Hostname is persistent in /etc/hostname" \
    "Hostname not in /etc/hostname"

# Check /etc/hosts has alias
check 'grep -q "rhcsa1" /etc/hosts' \
    "rhcsa1 alias exists in /etc/hosts" \
    "rhcsa1 alias not in /etc/hosts"
