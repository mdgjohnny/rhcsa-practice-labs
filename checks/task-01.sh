#!/usr/bin/env bash
# Task: Add a secondary IP address 10.0.99.1/24 to your primary network interface. The IP must persist across reboots.
# Title: Configure Secondary IP Address
# Category: networking
# Target: node1

# Check if secondary IP is configured on any interface
check 'ip addr show | grep -q "10.0.99.1"' \
    "Secondary IP 10.0.99.1 is configured" \
    "Secondary IP 10.0.99.1 is not configured"

# Check if it's persistent - stored in NetworkManager connection files
check 'grep -rq "10.0.99.1" /etc/NetworkManager/system-connections/ 2>/dev/null || grep -rq "10.0.99.1" /etc/sysconfig/network-scripts/ 2>/dev/null' \
    "Secondary IP is persistent (saved in config)" \
    "Secondary IP is not persistent (will be lost on reboot)"
