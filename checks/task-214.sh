#!/usr/bin/env bash
# Task: Restore default SELinux contexts for the entire /var/www directory recursively.
# Title: Restore Directory Context Recursively
# Category: security
# Target: node1
# Setup: mkdir -p /var/www/html; touch /var/www/html/test{1,2,3}.html; chcon -R -t tmp_t /var/www

check 'ls -Z /var/www/html/ 2>/dev/null | grep -q "httpd_sys_content_t"' \
    "Files have correct httpd_sys_content_t context" \
    "Files don't have correct context"
