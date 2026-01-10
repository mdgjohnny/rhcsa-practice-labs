#!/usr/bin/env bash
# Task: Configure httpd with DocumentRoot /webfiles. Create index.html containing "hello world".
# Title: Configure Apache DocumentRoot
# Category: operate-systems
# Target: node1

# Check httpd is running
check 'systemctl is-active httpd &>/dev/null' \
    "httpd service is running" \
    "httpd service is not running"

# Check /webfiles directory exists
check '[[ -d /webfiles ]]' \
    "Directory /webfiles exists" \
    "Directory /webfiles does not exist"

# Check index.html has correct content
check 'grep -q "hello world" /webfiles/index.html 2>/dev/null' \
    "index.html contains 'hello world'" \
    "index.html missing or wrong content"

# Check DocumentRoot is configured
check 'grep -rq "DocumentRoot.*/webfiles" /etc/httpd/conf/ /etc/httpd/conf.d/ 2>/dev/null' \
    "DocumentRoot is set to /webfiles" \
    "DocumentRoot is not /webfiles"

# Check SELinux context
check 'ls -Zd /webfiles 2>/dev/null | grep -q "httpd_sys_content_t"' \
    "/webfiles has correct SELinux context" \
    "/webfiles missing httpd_sys_content_t"

# Check web server responds
check 'curl -s http://localhost/ 2>/dev/null | grep -q "hello world"' \
    "Web server serves hello world" \
    "Web server not responding correctly"
