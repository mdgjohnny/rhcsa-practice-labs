#!/usr/bin/env bash
# Task: Using a manual method , configure a network connection on the primary network device with IP address 192.168.122.241/24, gateway 192.168.122.1, and nameserver
# Category: networking
# EXPECTED_IP: 192.168.122.241
# Target: node1

# Check IP address is configured
# Check IP address is configured
check 'run_ssh "$NODE1_IP" "ip addr show" 2>/dev/null | grep -q "192.168.122.241"' \
    "IP address 192.168.122.241 is currently active" \
    "IP address 192.168.122.241 is not configured"

# Check default gateway
check 'run_ssh "$NODE1_IP" "ip route show default" 2>/dev/null | grep -q "192.168.122.1"' \
    "Default gateway is 192.168.122.1" \
    "Default gateway is not 192.168.122.1"

# Check DNS nameserver
check 'run_ssh "$NODE1_IP" "grep nameserver /etc/resolv.conf" 2>/dev/null | grep -q "192.168.122.1"' \
    "DNS nameserver is configured" \
    "DNS nameserver is not configured"
