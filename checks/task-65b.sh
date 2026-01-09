#!/usr/bin/env bash
# Task: Verify /var/tmp/remote contains copied files from node1
# Title: Verify SSH Copy (node2)
# Category: security
# Target: node2

check '[[ -d /var/tmp/remote ]]' \
    "/var/tmp/remote directory exists" \
    "/var/tmp/remote does not exist"

check '[[ $(ls /var/tmp/remote/ 2>/dev/null | wc -l) -gt 0 ]]' \
    "/var/tmp/remote contains files" \
    "/var/tmp/remote is empty"
