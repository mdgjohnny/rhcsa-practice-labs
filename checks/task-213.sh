#!/usr/bin/env bash
# Task: The file /var/www/html/index.html has incorrect SELinux context. Restore it to the default context for that location.
# Title: Restore Default File Context
# Category: security
# Target: node1
# Setup: mkdir -p /var/www/html; echo "test" > /var/www/html/index.html; chcon -t tmp_t /var/www/html/index.html

check 'ls -Z /var/www/html/index.html 2>/dev/null | grep -q "httpd_sys_content_t"' \
    "File has correct httpd_sys_content_t context" \
    "File context is not httpd_sys_content_t"
