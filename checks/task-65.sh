#!/usr/bin/env bash
# Task: Configure passwordless SSH for user100 from rhcsa1 to rhcsa2
# Title: Passwordless SSH (user100)
# Category: security
# Target: node1

check 'su - user100 -c "ssh -o BatchMode=yes -o ConnectTimeout=5 rhcsa2 exit" &>/dev/null' \
    "user100 can SSH to rhcsa2 without password" \
    "user100 cannot SSH to rhcsa2 without password"
