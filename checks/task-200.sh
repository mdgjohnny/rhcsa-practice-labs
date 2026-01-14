#!/usr/bin/env bash
# Task: Create a new firewall zone named "custom" and configure it to allow only SSH and HTTPS services.
# Title: Create Custom Firewall Zone
# Category: security
# Target: node1

check 'firewall-cmd --get-zones 2>/dev/null | grep -q "custom"' \
    "Firewall zone 'custom' exists" \
    "Zone 'custom' not found (hint: firewall-cmd --new-zone)"

check 'firewall-cmd --permanent --zone=custom --list-services 2>/dev/null | grep -q "ssh"' \
    "Zone allows SSH service" \
    "SSH service not in zone"

check 'firewall-cmd --permanent --zone=custom --list-services 2>/dev/null | grep -q "https"' \
    "Zone allows HTTPS service" \
    "HTTPS service not in zone"
