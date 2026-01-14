#!/usr/bin/env bash
# Task: List all files from the "setup" package that contain "hosts" in their path. Save the full paths to /var/tmp/setup.pkg.
# Title: List Package Files by Pattern
# Category: deploy-maintain
# Target: node1

check '[[ -f /var/tmp/setup.pkg ]]' \
    "File /var/tmp/setup.pkg exists" \
    "File /var/tmp/setup.pkg does not exist"

check '[[ -s /var/tmp/setup.pkg ]]' \
    "File has content" \
    "File is empty"

check 'grep -q "/etc/hosts" /var/tmp/setup.pkg 2>/dev/null' \
    "File contains /etc/hosts" \
    "File should contain /etc/hosts"
