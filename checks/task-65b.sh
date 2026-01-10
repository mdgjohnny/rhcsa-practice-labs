#!/usr/bin/env bash
# Task: Verify that /var/tmp/remote contains files copied from node1 via SSH.
# Title: Verify SSH Copy
# Category: security
# Target: node2

check '[[ -d /var/tmp/remote ]]' \
    "/var/tmp/remote directory exists" \
    "/var/tmp/remote does not exist"

check '[[ $(ls /var/tmp/remote/ 2>/dev/null | wc -l) -gt 0 ]]' \
    "/var/tmp/remote contains files" \
    "/var/tmp/remote is empty"
