#!/usr/bin/env bash
# Task: Use chcon to temporarily change /root/testfile.txt to type httpd_sys_content_t. Then use restorecon to restore it.
# Title: chcon and restorecon Practice
# Category: security
# Target: node1
# Setup: touch /root/testfile.txt

check 'ls -Z /root/testfile.txt 2>/dev/null | grep -qE "admin_home_t|user_home_t"' \
    "File context restored to default" \
    "File context not restored"
