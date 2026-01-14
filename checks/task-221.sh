#!/usr/bin/env bash
# Task: Apache is configured to serve files from /custom/webroot but returns 403 Forbidden errors. The files exist and have correct Unix permissions (755 for directory, 644 for files). Diagnose and fix the issue so Apache can serve the content.
# Title: Fix Web Content Access Issue
# Category: security
# Target: node1
# Setup: mkdir -p /custom/webroot; echo "test" > /custom/webroot/index.html; chmod 755 /custom/webroot; chmod 644 /custom/webroot/index.html

check 'ls -Z /custom/webroot/index.html 2>/dev/null | grep -qE "httpd_sys_content_t|public_content_t"' \
    "Web files have correct security context" \
    "Web files have incorrect security context (check ls -Z)"
