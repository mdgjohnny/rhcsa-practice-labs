#!/usr/bin/env bash
# Task: Enable the boolean "httpd_use_nfs" to allow Apache to access NFS shares. Make it persistent.
# Title: Enable httpd NFS Boolean
# Category: security
# Target: node1

check 'getsebool httpd_use_nfs 2>/dev/null | grep -q "on"' \
    "httpd_use_nfs is enabled" \
    "httpd_use_nfs not enabled"
