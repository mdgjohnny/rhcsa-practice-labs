#!/usr/bin/env bash
# Task: Add port 8888/TCP to the SELinux http_port_t type. This allows HTTP services to bind to port 8888.
# Title: Add Custom SELinux HTTP Port
# Category: security
# Target: node1

check 'semanage port -l 2>/dev/null | grep http_port_t | grep -q 8888' \
    "Port 8888 is assigned to http_port_t" \
    "Port 8888 not found in http_port_t"
