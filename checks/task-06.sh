#!/usr/bin/env bash
# Task: A web application needs to run on port 8081, but the security policy only allows HTTP services on standard ports. Configure the system to permit HTTP services to bind to port 8081/TCP. The change must be persistent.
# Title: Allow HTTP Service on Port 8081
# Category: security
# Target: node1

check 'semanage port -l 2>/dev/null | grep -w "8081" | grep -q "http_port_t"' \
    "Port 8081/TCP is allowed for HTTP services" \
    "Port 8081/TCP is not configured for HTTP (hint: semanage port)"
