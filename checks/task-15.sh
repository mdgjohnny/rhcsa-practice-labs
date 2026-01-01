#!/usr/bin/env bash
# Task: List files from setup package containing "hosts" to /var/tmp/setup.pkg
# Category: deploy-maintain

check '[[ -f /var/tmp/setup.pkg ]]' \
    "File /var/tmp/setup.pkg exists" \
    "File /var/tmp/setup.pkg does not exist"

check 'grep -q hosts /var/tmp/setup.pkg 2>/dev/null' \
    "/var/tmp/setup.pkg contains lines with 'hosts'" \
    "/var/tmp/setup.pkg does not contain 'hosts'"
