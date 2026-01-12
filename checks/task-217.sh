#!/usr/bin/env bash
# Task: List all ports assigned to the http_port_t type. Save output to /root/http-ports.txt.
# Title: List HTTP SELinux Ports
# Category: security
# Target: node1

check '[[ -f /root/http-ports.txt ]]' \
    "File /root/http-ports.txt exists" \
    "File not found"

check 'grep -q "http_port_t" /root/http-ports.txt' \
    "File contains http_port_t" \
    "http_port_t not found in file"

check 'grep -qE "80|443|8080" /root/http-ports.txt' \
    "File lists common HTTP ports" \
    "Common ports not found"
