#!/usr/bin/env bash
# Task: Set hostname to rhcsa1 on node1
# Title: Set Hostname (node1)
# Category: networking
# Target: node1

check 'run_ssh "$NODE1_IP" "hostname -s" 2>/dev/null | grep -q "^rhcsa1$"' \
    "Hostname set to rhcsa1" \
    "Hostname not set to rhcsa1"
