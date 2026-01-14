#!/usr/bin/env bash
# Task: Copy /etc/hostname from node1 to node2:/var/tmp/remote/ using scp or rsync.
# Title: Copy Files Between Nodes via SSH
# Category: networking
# Target: node2

check '[[ -d /var/tmp/remote ]]' \
    "Directory /var/tmp/remote exists" \
    "/var/tmp/remote does not exist"

check '[[ -f /var/tmp/remote/hostname ]]' \
    "File hostname was copied" \
    "hostname file not found in /var/tmp/remote"

check 'grep -q "rhcsa1" /var/tmp/remote/hostname 2>/dev/null' \
    "hostname file contains rhcsa1 (from node1)" \
    "hostname file doesn't contain expected content"
