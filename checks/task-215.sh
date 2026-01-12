#!/usr/bin/env bash
# Task: Add port 8443/TCP to the SELinux http_port_t type to allow HTTPS on that port.
# Title: Add HTTPS SELinux Port
# Category: security
# Target: node1

check 'semanage port -l 2>/dev/null | grep http_port_t | grep -q 8443' \
    "Port 8443 is assigned to http_port_t" \
    "Port 8443 not in http_port_t"
