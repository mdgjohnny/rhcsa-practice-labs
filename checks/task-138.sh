#!/usr/bin/env bash
# Task: Add a secondary IP address 192.168.0.241/24 to the network interface using nmcli. Configure it persistently. This tests manual network configuration skills.
# Title: Manual Network Configuration (Secondary IP)
# Category: networking
# Target: node1

# Check if secondary IP is configured
check 'ip addr show | grep -q "192.168.0.241"' \
    "IP address 192.168.0.241 is configured" \
    "IP address 192.168.0.241 is not configured"

# Check persistence via nmcli
check 'nmcli -g ipv4.addresses con show "$(nmcli -t -f NAME con show --active | head -1)" 2>/dev/null | grep -q "192.168.0.241"' \
    "IP configured persistently via nmcli" \
    "IP not found in nmcli connection (may not persist)"
