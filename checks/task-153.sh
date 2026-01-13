#!/usr/bin/env bash
# Task: Create directory /webdata. Configure SELinux so Apache (httpd) can serve files from this directory. The context must persist after relabeling.
# Title: SELinux Context for Web Content
# Category: security
# Target: node1


check '[[ -d /webdata ]]' \
    "Directory /webdata exists" \
    "Directory /webdata does not exist"

check 'ls -Zd /webdata 2>/dev/null | grep -q "httpd_sys_content_t"' \
    "/webdata has correct SELinux context" \
    "/webdata does not have correct context"

check 'semanage fcontext -l | grep -q "/webdata"' \
    "SELinux context rule is persistent" \
    "SELinux context rule not persistent"
