#!/usr/bin/env bash
# Task: Verify root SSH access to node2

ssh -o BatchMode=yes -o ConnectTimeout=5 root@"$NODE2_IP" exit &>/dev/null
RETURN_STATUS=$?

check '[[ "$RETURN_STATUS" -eq 0 ]]' \
    "Can SSH as root into node2 ($NODE2_IP)" \
    "Cannot SSH as root into node2 ($NODE2_IP)"
