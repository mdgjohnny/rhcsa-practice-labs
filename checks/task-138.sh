#!/usr/bin/env bash
# Task: Configure a secondary IP address 10.0.99.3/24 manually (using nmcli or ip command). Make it persistent.
# Title: Manual Network Configuration (Secondary IP)
# Category: networking
# Target: node1

# Check if secondary IP is configured
check 'ip addr show | grep -q "10.0.99.3"' \
    "Secondary IP 10.0.99.3 is configured" \
    "Secondary IP 10.0.99.3 is not configured"

# Check persistence
check 'nmcli -g ipv4.addresses con show 2>/dev/null | grep -q "10.0.99.3" || grep -rq "10.0.99.3" /etc/sysconfig/network-scripts/ 2>/dev/null || ip link show dummy0 &>/dev/null' \
    "Secondary IP configuration is persistent" \
    "Secondary IP may not persist after reboot"
