#!/usr/bin/env bash
# Task: Configure httpd with DocumentRoot /webfiles. Create index.html with "hello world".
# Title: Configure Apache DocumentRoot
# Category: deploy-maintain
# Target: node1
# rhcsa2 should be able to access via curl

check '[[ -d /webfiles ]]' \
    "Directory /webfiles exists" \
    "Directory /webfiles does not exist"

check '[[ -f /webfiles/index.html ]]' \
    "File /webfiles/index.html exists" \
    "File /webfiles/index.html does not exist"

check 'grep -qi "hello world" /webfiles/index.html 2>/dev/null' \
    "index.html contains 'hello world'" \
    "index.html does not contain 'hello world'"

check 'systemctl is-active httpd &>/dev/null' \
    "httpd service is running" \
    "httpd service is not running"

check 'curl -s http://localhost/ 2>/dev/null | grep -qi "hello world"' \
    "Web server serves 'hello world'" \
    "Web server does not serve expected content"
