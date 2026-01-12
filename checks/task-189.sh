#!/usr/bin/env bash
# Task: Create /root/secret.txt with content "confidential". Set permissions so only root can read and write it (no execute, no access for group/others).
# Title: Set Restrictive File Permissions
# Category: essential-tools
# Target: node1

check '[[ -f /root/secret.txt ]]' \
    "File /root/secret.txt exists" \
    "File /root/secret.txt not found"

check 'grep -q "confidential" /root/secret.txt' \
    "File contains correct content" \
    "File doesn't contain expected content"

check '[[ $(stat -c %a /root/secret.txt) == "600" ]]' \
    "Permissions are 600 (rw-------)" \
    "Permissions are not 600"
