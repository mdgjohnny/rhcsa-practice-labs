#!/usr/bin/env bash
# Task: Create HTTP container mounting /httproot to /var/www/html
# Category: containers
# Target: node1


check '[[ -d /httproot ]]' \
    "Directory /httproot exists" \
    "Directory /httproot does not exist"
check '[[ -d /var/www/html ]]' \
    "Directory /var/www/html exists" \
    "Directory /var/www/html does not exist"
check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
