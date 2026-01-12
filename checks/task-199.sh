#!/usr/bin/env bash
# Task: Add a firewall rich rule to allow TCP connections on port 9000 only from the 10.0.0.0/8 network. Make it permanent.
# Title: Configure Firewall Rich Rule
# Category: security
# Target: node1

check 'firewall-cmd --list-rich-rules 2>/dev/null | grep -q "9000"' \
    "Rich rule for port 9000 exists" \
    "No rich rule for port 9000 found"

check 'firewall-cmd --list-rich-rules 2>/dev/null | grep 9000 | grep -q "10.0.0.0"' \
    "Rule restricts to 10.0.0.0/8 network" \
    "Rule doesn't restrict to correct network"

check 'firewall-cmd --permanent --list-rich-rules 2>/dev/null | grep -q "9000"' \
    "Rule is permanent" \
    "Rule is not permanent"
