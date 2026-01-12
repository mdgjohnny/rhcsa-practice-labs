#!/usr/bin/env bash
# Task: A web application at /opt/webapp can't be served by Apache. The files have wrong context. Fix it by setting httpd_sys_content_t recursively.
# Title: Fix Web Application SELinux Context
# Category: security
# Target: node1
# Setup: mkdir -p /opt/webapp; echo "test" > /opt/webapp/index.html; chcon -R -t tmp_t /opt/webapp

check 'ls -Z /opt/webapp/index.html 2>/dev/null | grep -q "httpd_sys_content_t"' \
    "Web app files have correct context" \
    "Files don't have httpd_sys_content_t"
