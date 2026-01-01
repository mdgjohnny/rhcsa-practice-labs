#!/usr/bin/env bash
# Task: Add HTTP port 8400/UDP to public firewall zone persistently
# Category: security

check 'firewall-cmd --zone=public --list-ports | grep -q "8400/udp"' \
    "Port 8400/UDP is open in public zone" \
    "Port 8400/UDP is not open in public zone"

check 'firewall-cmd --permanent --zone=public --list-ports | grep -q "8400/udp"' \
    "Port 8400/UDP is persistent in public zone" \
    "Port 8400/UDP is not persistent"
