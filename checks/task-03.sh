#!/usr/bin/env bash
# Task: Set hostname to rhcsa1 on node1
# Title: Set Hostname (node1)
# Category: networking
# Target: node1

check 'hostname -s | grep -q "^rhcsa1$"' \
    "Hostname set to rhcsa1" \
    "Hostname not set to rhcsa1 (got $(hostname -s))"
