#!/usr/bin/env bash
# Task: Add secondary IP 10.0.99.1/24 to interface ens3 (or your primary interface). Use: nmcli con mod <connection> +ipv4.addresses 10.0.99.1/24
# Title: Configure Secondary IP Address
# Category: networking
# Target: node1

# Check if secondary IP is configured on any interface
check 'ip addr show | grep -q "10.0.99.1"' \
    "Secondary IP 10.0.99.1 is configured on an interface" \
    "Secondary IP 10.0.99.1 is NOT configured (use: ip addr show to verify)"

# Check if it's persistent (in nmcli)
check 'nmcli -g ipv4.addresses con show 2>/dev/null | grep -q "10.0.99.1" || grep -rq "10.0.99.1" /etc/sysconfig/network-scripts/ 2>/dev/null || grep -q "10.0.99.1" /etc/NetworkManager/system-connections/* 2>/dev/null' \
    "Secondary IP is persistent (saved in NetworkManager)" \
    "Secondary IP is NOT persistent (use: nmcli con mod <name> +ipv4.addresses 10.0.99.1/24)"
