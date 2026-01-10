#!/usr/bin/env bash
# Task: Set the system hostname to "rhcsa1". The hostname must persist across reboots and be resolvable locally.
# Title: Set System Hostname
# Category: networking
# Target: node1

check 'hostname -s | grep -q "^rhcsa1$"' \
    "Hostname set to rhcsa1" \
    "Hostname not set to rhcsa1 (got $(hostname -s))"
