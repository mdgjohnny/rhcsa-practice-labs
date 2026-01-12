#!/usr/bin/env bash
# Task: Use podman to view the logs of a running container named "webserver" and save to /root/webserver-logs.txt.
# Title: View Container Logs
# Category: containers
# Target: node1
# Setup: podman run -d --name webserver httpd

check '[[ -f /root/webserver-logs.txt ]]' \
    "Log file exists" \
    "Log file not found"
