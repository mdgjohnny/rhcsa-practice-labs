#!/usr/bin/env bash
# Task: Add a secondary IP address 10.0.99.2/24 to a network interface. Configure it persistently. Verify with: ip addr show
# Title: Configure Secondary IP Address
# Category: networking
# Target: node2

# Check if secondary IP is configured on any interface
check 'ip addr show | grep -q "10.0.99.2"' \
    "Secondary IP 10.0.99.2 is configured" \
    "Secondary IP 10.0.99.2 is not configured on any interface"

# Check if it's persistent
check 'nmcli -g ipv4.addresses con show 2>/dev/null | grep -q "10.0.99.2" || grep -rq "10.0.99.2" /etc/sysconfig/network-scripts/ 2>/dev/null || grep -q "10.0.99.2" /etc/NetworkManager/system-connections/* 2>/dev/null || ip link show dummy0 &>/dev/null' \
    "Secondary IP is configured persistently" \
    "Secondary IP may not persist after reboot"
