#!/usr/bin/env bash
# Task: Apache is failing to serve files from /custom/webroot. The files exist and have correct Unix permissions. Diagnose and fix the SELinux issue.
# Title: Fix SELinux Web Content Issue
# Category: security
# Target: node1
# Setup: mkdir -p /custom/webroot; echo "test" > /custom/webroot/index.html; chmod 755 /custom/webroot; chmod 644 /custom/webroot/index.html

check 'ls -Z /custom/webroot/index.html 2>/dev/null | grep -qE "httpd_sys_content_t|public_content_t"' \
    "Web files have correct SELinux context" \
    "Web files don't have httpd-compatible context"
