#!/usr/bin/env bash
# Task: Inspect the httpd image and list its exposed ports. Save to /root/httpd-ports.txt.
# Title: Inspect Image Exposed Ports
# Category: containers
# Target: node1

check '[[ -f /root/httpd-ports.txt ]]' \
    "File /root/httpd-ports.txt exists" \
    "File not found"

check 'grep -qE "80|8080" /root/httpd-ports.txt' \
    "File contains exposed port information" \
    "No port information found"
