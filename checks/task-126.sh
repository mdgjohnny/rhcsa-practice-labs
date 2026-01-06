#!/usr/bin/env bash
# Task: Configure a web server to use the nondefault document root /webfiles. In this directory, create a file index.html that has the contents hello world and then test that it works
# Category: operate-systems
# Target: node1

# Check httpd is running
check \'run_ssh "$NODE1_IP" "systemctl is-active httpd &>/dev/null"\' \
    "httpd service is running" \
    "httpd service is not running"

# Check /webfiles directory exists
check \'run_ssh "$NODE1_IP" "test -d /webfiles"\' \
    "Directory /webfiles exists" \
    "Directory /webfiles does not exist"

# Check index.html has correct content
check \'run_ssh "$NODE1_IP" "grep -q "hello world" /webfiles/index.html 2>/dev/null"\' \
    "index.html contains 'hello world'" \
    "index.html missing or wrong content"

# Check DocumentRoot is configured
check \'run_ssh "$NODE1_IP" "grep -rq "DocumentRoot.*/webfiles" /etc/httpd/conf/ /etc/httpd/conf.d/ 2>/dev/null"\' \
    "DocumentRoot is set to /webfiles" \
    "DocumentRoot is not /webfiles"

# Check SELinux context
check \'run_ssh "$NODE1_IP" "ls -Zd /webfiles 2>/dev/null | grep -q "httpd_sys_content_t""\' \
    "/webfiles has correct SELinux context" \
    "/webfiles missing httpd_sys_content_t"

# Check web server responds
check 'curl -s http://localhost/ 2>/dev/null | grep -q "hello world"' \
    "Web server serves hello world" \
    "Web server not responding correctly"
