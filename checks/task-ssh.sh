#!/usr/bin/env bash
# Task: Verify SSH connectivity between nodes
# Title: Verify SSH Access
# Category: essential-tools
# Target: node1

# Test SSH to node2 (by hostname or IP)
check 'ssh -o BatchMode=yes -o ConnectTimeout=5 rhcsa2 exit &>/dev/null || ssh -o BatchMode=yes -o ConnectTimeout=5 "$NODE2_IP" exit &>/dev/null' \
    "Can SSH to node2" \
    "Cannot SSH to node2"
