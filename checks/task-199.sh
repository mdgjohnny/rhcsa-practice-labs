#!/usr/bin/env bash
# Task: A web application runs on port 9000. Configure the firewall to allow incoming TCP traffic on this port. The change must persist across reboots.
# Title: Allow Traffic on Port 9000
# Category: security
# Target: node1

check 'firewall-cmd --list-ports 2>/dev/null | grep -q "9000/tcp"' \
    "Port 9000/TCP is allowed in firewall" \
    "Port 9000/TCP is not open in firewall"

check 'firewall-cmd --permanent --list-ports 2>/dev/null | grep -q "9000/tcp"' \
    "Rule is permanent" \
    "Rule will not persist after reboot (use --permanent)"
