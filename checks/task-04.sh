#!/usr/bin/env bash
# Task: Set hostname to rhcsa2 on node2
# Title: Set Hostname (node2)
# Category: networking
# Target: node2

check 'run_ssh "$NODE2_IP" "hostname -s" 2>/dev/null | grep -q "^rhcsa2$"' \
    "Hostname set to rhcsa2" \
    "Hostname not set to rhcsa2"
