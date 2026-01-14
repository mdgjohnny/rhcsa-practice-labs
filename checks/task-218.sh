#!/usr/bin/env bash
# Task: You need to configure Apache to serve user web content from ~/public_html directories. SELinux blocks this by default. Find and enable the boolean that allows httpd to access content in user home directories. Make it persistent.
# Title: Fix Apache User Home Directory Access (SELinux)
# Category: security
# Target: node1

check 'getsebool httpd_enable_homedirs 2>/dev/null | grep -q "on"' \
    "Correct SELinux boolean is enabled" \
    "Required boolean is not enabled (hint: search httpd booleans related to home)"
