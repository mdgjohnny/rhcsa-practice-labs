#!/usr/bin/env bash
# Task: Start an httpd container named "webserver" in detached mode. Then view its logs and save them to /root/webserver-logs.txt.
# Title: View Container Logs
# Category: containers
# Target: node1

check 'podman ps -a --format "{{.Names}}" | grep -q "^webserver$"' \
    "Container webserver exists" \
    "Container webserver not found"

check '[[ -f /root/webserver-logs.txt ]]' \
    "Log file /root/webserver-logs.txt exists" \
    "Log file not found"

check '[[ -s /root/webserver-logs.txt ]]' \
    "Log file has content" \
    "Log file is empty"
