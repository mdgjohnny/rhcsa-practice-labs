#!/usr/bin/env bash
# Task: Change Apache document root to /web with index.html 'welcome to my web server', fix SELinux
# Category: deploy-maintain
# Target: node1

# Check if httpd is running
check 'systemctl is-active httpd &>/dev/null' \
    "httpd service is running" \
    "httpd service is not running"

# Check if /web directory exists
check '[[ -d /web ]]' \
    "Directory /web exists" \
    "Directory /web does not exist"

# Check if index.html exists with correct content
check 'grep -q "welcome to my web server" /web/index.html 2>/dev/null' \
    "index.html has correct content" \
    "index.html missing or has wrong content"

# Check if DocumentRoot is changed in config
check 'grep -rq "DocumentRoot.*/web" /etc/httpd/conf/ /etc/httpd/conf.d/ 2>/dev/null' \
    "DocumentRoot is set to /web" \
    "DocumentRoot is not set to /web"

# Check if SELinux context is correct
check 'ls -Zd /web 2>/dev/null | grep -q "httpd_sys_content_t"' \
    "/web has correct SELinux context" \
    "/web does not have httpd_sys_content_t context"

# Check if web server is accessible
check 'curl -s http://localhost/ 2>/dev/null | grep -q "welcome"' \
    "Web server serves content from /web" \
    "Web server not accessible or wrong content"
