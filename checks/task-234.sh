#!/usr/bin/env bash
# Task: Pull the httpd image if not present, inspect it to list its exposed ports, and save the port numbers to /root/httpd-ports.txt.
# Title: Inspect Image Exposed Ports
# Category: containers
# Target: node1

check '[[ -f /root/httpd-ports.txt ]]' \
    "File /root/httpd-ports.txt exists" \
    "File not found"

check '[[ -s /root/httpd-ports.txt ]]' \
    "File has content" \
    "File is empty"

check 'grep -qE "80" /root/httpd-ports.txt' \
    "File contains port 80" \
    "Port 80 not found in file"
