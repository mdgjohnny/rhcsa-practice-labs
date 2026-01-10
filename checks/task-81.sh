#!/usr/bin/env bash
# Task: Set up passwordless SSH authentication between both nodes in both directions.
# Title: Configure Bidirectional SSH Keys
# Category: networking
# Target: both

# Check if SSH key exists
check '[[ -f ~/.ssh/id_rsa ]] || [[ -f ~/.ssh/id_ed25519 ]]' \
    "SSH key pair exists" \
    "No SSH key pair found in ~/.ssh/"

# Check if we can SSH to node2 without password (from node1 context)
check 'ssh -o BatchMode=yes -o ConnectTimeout=5 root@$NODE2 exit 2>/dev/null' \
    "Passwordless SSH to node2 works" \
    "Passwordless SSH to node2 failed"
