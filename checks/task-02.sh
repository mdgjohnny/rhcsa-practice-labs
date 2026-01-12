#!/usr/bin/env bash
# Task: Add a secondary IP address 10.0.99.2/24 to your primary network interface. The IP must persist across reboots.
# Title: Configure Secondary IP Address
# Category: networking
# Target: node2

check 'ip addr show | grep -q "10.0.99.2"' \
    "Secondary IP 10.0.99.2 is configured" \
    "Secondary IP 10.0.99.2 is not configured"

check 'nmcli -g ipv4.addresses con show 2>/dev/null | grep -q "10.0.99.2" || grep -rq "10.0.99.2" /etc/NetworkManager/system-connections/ 2>/dev/null' \
    "Secondary IP is persistent in NetworkManager" \
    "Secondary IP is not persistent (will be lost on reboot)"
