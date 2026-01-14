#!/usr/bin/env bash
# Task: A monitoring agent needs to receive UDP traffic on port 8400. Configure the firewall to allow this in the public zone. The change must survive reboots.
# Title: Allow UDP Port for Monitoring
# Category: security
# Target: node1

check 'firewall-cmd --zone=public --list-ports 2>/dev/null | grep -q "8400/udp"' \
    "Port 8400/UDP is open in public zone" \
    "Port 8400/UDP is not open"

check 'firewall-cmd --permanent --zone=public --list-ports 2>/dev/null | grep -q "8400/udp"' \
    "Configuration is persistent" \
    "Rule will not survive reboot (use --permanent)"
