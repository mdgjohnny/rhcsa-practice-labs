#!/usr/bin/env bash
# Task: On rhcsa2 - Script defines ENV1=book1 and creates user matching variable

check 'ssh "$NODE2_IP" "id book1 &>/dev/null" 2>/dev/null' \
    "User book1 exists on node2" \
    "User book1 does not exist"
