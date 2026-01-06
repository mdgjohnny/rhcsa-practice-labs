#!/usr/bin/env bash
# Task: Change the Apache document root to /web. In this directory, create a file with the name index.html and give it the content welcome to my web server. Restart the httpd process and try to access the web server. This will not work. Fix the problem
# Category: deploy-maintain
# Target: node1

# Check if httpd is running
check \'run_ssh "$NODE1_IP" "systemctl is-active httpd &>/dev/null"\' \
    "httpd service is running" \
    "httpd service is not running"

# Check if /web directory exists
check \'run_ssh "$NODE1_IP" "test -d /web"\' \
    "Directory /web exists" \
    "Directory /web does not exist"

# Check if index.html exists with correct content
check \'run_ssh "$NODE1_IP" "grep -q "welcome to my web server" /web/index.html 2>/dev/null"\' \
    "index.html has correct content" \
    "index.html missing or has wrong content"

# Check if DocumentRoot is changed in config
check \'run_ssh "$NODE1_IP" "grep -rq "DocumentRoot.*/web" /etc/httpd/conf/ /etc/httpd/conf.d/ 2>/dev/null"\' \
    "DocumentRoot is set to /web" \
    "DocumentRoot is not set to /web"

# Check if SELinux context is correct
check \'run_ssh "$NODE1_IP" "ls -Zd /web 2>/dev/null | grep -q "httpd_sys_content_t""\' \
    "/web has correct SELinux context" \
    "/web does not have httpd_sys_content_t context"

# Check if web server is accessible
check 'curl -s http://localhost/ 2>/dev/null | grep -q "welcome"' \
    "Web server serves content from /web" \
    "Web server not accessible or wrong content"
