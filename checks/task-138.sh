#!/usr/bin/env bash
# Task: Configure network: IP 192.168.0.241/24, gateway 192.168.0.1, DNS 192.168.0.1. Must persist.
# Title: Configure Network Manually
# Category: networking
# Target: node1

# Check IP address is configured
check 'ip addr show | grep -q "192.168.0.241"' \
    "IP address 192.168.0.241 is configured" \
    "IP address 192.168.0.241 is not configured"

# Check default gateway
check 'ip route show default | grep -q "192.168.0.1"' \
    "Default gateway is 192.168.0.1" \
    "Default gateway is not 192.168.0.1"

# Check DNS nameserver
check 'grep -q "192.168.0.1\|nameserver" /etc/resolv.conf' \
    "DNS nameserver is configured" \
    "DNS nameserver is not configured"
