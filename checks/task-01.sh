#!/usr/bin/env bash
# Task: Add a secondary IP address 192.168.0.241/24 to the primary network interface. The IP must be configured persistently using nmcli or network-scripts. Verify with: ip addr show | grep 192.168.0.241
# Title: Configure Secondary IP Address
# Category: networking
# Target: node1

SECONDARY_IP="${SECONDARY_IP:-192.168.0.241}"

# Check if secondary IP is configured on any interface
check 'ip addr show | grep -q "192.168.0.241"' \
    "Secondary IP $SECONDARY_IP is configured" \
    "Secondary IP $SECONDARY_IP is not configured on any interface"

# Check if it's persistent (in nmcli or ifcfg files)
check 'nmcli con show --active 2>/dev/null | grep -q . && nmcli -g ipv4.addresses con show "$(nmcli -t -f NAME con show --active | head -1)" 2>/dev/null | grep -q "192.168.0.241" || grep -r "192.168.0.241" /etc/sysconfig/network-scripts/ 2>/dev/null | grep -q .' \
    "Secondary IP is configured persistently" \
    "Secondary IP may not persist after reboot (not found in nmcli or network-scripts)"
