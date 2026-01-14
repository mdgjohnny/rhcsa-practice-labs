#!/usr/bin/env bash
# Task: Your development team needs to run a web server on port 8888 for testing. Currently, the security policy blocks HTTP services from binding to this port. Update the policy to allow it. The change must survive reboots.
# Title: Allow HTTP Service on Port 8888
# Category: security
# Target: node1

check 'semanage port -l 2>/dev/null | grep -w "8888" | grep -q "http_port_t"' \
    "Port 8888/TCP is allowed for HTTP services" \
    "Port 8888/TCP is not configured for HTTP (hint: check semanage port)"
