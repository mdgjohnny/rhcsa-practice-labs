#!/usr/bin/env bash
# Task: Document all TCP ports currently allowed for web services in the security policy. Save the complete list to /root/http-ports.txt. (Click "Check Task" to verify)
# Title: Document Allowed HTTP Ports
# Category: security
# Target: node1

check '[[ -f /root/http-ports.txt ]]' \
    "File /root/http-ports.txt exists" \
    "File /root/http-ports.txt not found"

check 'grep -qE "80|443|8080" /root/http-ports.txt 2>/dev/null' \
    "File contains standard HTTP/HTTPS ports" \
    "File should contain HTTP port information"

check 'grep -qi "http" /root/http-ports.txt 2>/dev/null' \
    "File appears to contain HTTP port policy data" \
    "File content doesn't look like HTTP port data"
