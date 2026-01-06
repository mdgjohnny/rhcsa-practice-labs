#!/usr/bin/env bash
# Task: Configure network on node2 with IP 192.168.122.242/24, gateway 192.168.122.1, DNS 192.168.122.1
# Category: networking
# EXPECTED_IP: 192.168.122.242

IPV4_ADDR="${IPV4_ADDR:-192.168.122.242/24}"
IPV4_GW="${IPV4_GW:-192.168.122.1}"
IPV4_DNS="${IPV4_DNS:-192.168.122.1}"

# Run checks on node2 via SSH
# We use ip addr show because hostname -I might return multiple IPs in unpredictable order

check 'run_ssh "$NODE2_IP" "ip addr show" 2>/dev/null | grep -q "192.168.122.242"' \
    "Node2 IPv4 address 192.168.122.242 is currently active" \
    "Node2 IPv4 address 192.168.122.242 is NOT configured"

# Check Gateway
check 'run_ssh "$NODE2_IP" "ip route show default" 2>/dev/null | grep -q "192.168.122.1"' \
    "Node2 IPv4 gateway set to 192.168.122.1" \
    "Node2 IPv4 gateway NOT set to 192.168.122.1"

# Check DNS
check 'run_ssh "$NODE2_IP" "grep nameserver /etc/resolv.conf" 2>/dev/null | grep -q "192.168.122.1"' \
    "Node2 IPv4 DNS set to 192.168.122.1" \
    "Node2 IPv4 DNS NOT set to 192.168.122.1"
