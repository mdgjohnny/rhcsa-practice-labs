#!/usr/bin/env bash
# Task: Lock the user70 account. Save the lock line from /etc/shadow to /var/tmp/user70.lock
# Title: Lock User Account
# Category: users-groups

check 'passwd -S user70 2>/dev/null | grep -qE "^user70 L|^user70.*locked"' \
    "User user70 account is locked" \
    "User user70 account is not locked"

check '[[ -f /var/tmp/user70.lock ]]' \
    "File /var/tmp/user70.lock exists" \
    "File /var/tmp/user70.lock does not exist"

check 'grep -q user70 /var/tmp/user70.lock 2>/dev/null' \
    "/var/tmp/user70.lock contains user70 info" \
    "/var/tmp/user70.lock does not contain expected info"
