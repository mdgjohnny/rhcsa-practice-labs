#!/usr/bin/env bash
# Task: Create a new firewall zone called "custom" that allows only SSH and HTTPS services. Assign the primary interface to this zone permanently.
# Title: Create Custom Firewall Zone
# Category: security
# Target: node1

check 'firewall-cmd --get-zones 2>/dev/null | grep -q "custom"' \
    "Firewall zone 'custom' exists" \
    "Zone 'custom' not found"

check 'firewall-cmd --zone=custom --list-services 2>/dev/null | grep -qE "ssh.*https|https.*ssh"' \
    "Zone allows SSH and HTTPS" \
    "Zone doesn't have correct services"
