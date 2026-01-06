#!/usr/bin/env bash
# Task: Configure network on node1 with IP 192.168.122.241/24, gateway 192.168.122.1, DNS 192.168.122.1
# Category: networking
# EXPECTED_IP: 192.168.122.241

IPV4_ADDR="${IPV4_ADDR:-192.168.122.241/24}"
IPV4_GW="${IPV4_GW:-192.168.122.1}"
IPV4_DNS="${IPV4_DNS:-192.168.122.1}"

# Run checks on node1 via SSH
# We use ip addr show because hostname -I might return multiple IPs in unpredictable order
# The task passes if the specific IP is configured on any interface

check 'run_ssh "$NODE1_IP" "ip addr show" 2>/dev/null | grep -q "192.168.122.241"' \
    "IPv4 address 192.168.122.241 is currently active" \
    "IPv4 address 192.168.122.241 is NOT configured (or not creating a route? check with ip a)"

# Check Gateway
check 'run_ssh "$NODE1_IP" "ip route show default" 2>/dev/null | grep -q "192.168.122.1"' \
    "IPv4 gateway set to 192.168.122.1" \
    "IPv4 gateway NOT set to 192.168.122.1"

# Check DNS
check 'run_ssh "$NODE1_IP" "grep nameserver /etc/resolv.conf" 2>/dev/null | grep -q "192.168.122.1"' \
    "IPv4 DNS set to 192.168.122.1" \
    "IPv4 DNS NOT set to 192.168.122.1"
