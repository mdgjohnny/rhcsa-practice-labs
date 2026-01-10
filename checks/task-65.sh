#!/usr/bin/env bash
# Task: Set up SSH key-based authentication for user100 to connect from rhcsa1 to rhcsa2 without password.
# Title: Configure Passwordless SSH
# Category: security
# Target: node1

check 'su - user100 -c "ssh -o BatchMode=yes -o ConnectTimeout=5 rhcsa2 exit" &>/dev/null' \
    "user100 can SSH to rhcsa2 without password" \
    "user100 cannot SSH to rhcsa2 without password"
