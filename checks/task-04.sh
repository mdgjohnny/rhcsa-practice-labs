#!/usr/bin/env bash
# Task: Set the system hostname to "rhcsa2". The hostname must persist across reboots and be resolvable locally.
# Title: Set System Hostname
# Category: networking
# Target: node2

check 'hostname -s | grep -q "^rhcsa2$"' \
    "Hostname set to rhcsa2" \
    "Hostname not set to rhcsa2 (got $(hostname -s))"
