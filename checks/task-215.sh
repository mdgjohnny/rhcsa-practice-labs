#!/usr/bin/env bash
# Task: An internal application requires HTTPS on port 8443 for secure API communication. The security policy must be updated to allow this. Make the change persistent. (Click "Check Task" to verify)
# Title: Allow HTTPS Service on Port 8443
# Category: security
# Target: node1

check 'semanage port -l 2>/dev/null | grep -w "8443" | grep -q "http_port_t"' \
    "Port 8443/TCP is allowed for HTTPS services" \
    "Port 8443/TCP is not configured for HTTP/HTTPS (hint: semanage port -l | grep http)"
