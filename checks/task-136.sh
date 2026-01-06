#!/usr/bin/env bash
# Task: Install httpd and configure to listen on port 8080
# Category: deploy-maintain
# Target: node1

# Check httpd is installed
check 'rpm -q httpd &>/dev/null' \
    "httpd package is installed" \
    "httpd package is not installed"

# Check httpd is running
check 'systemctl is-active httpd &>/dev/null' \
    "httpd service is running" \
    "httpd service is not running"

# Check port 8080 is configured in httpd
check 'grep -rq "Listen.*8080\|:8080" /etc/httpd/conf/ /etc/httpd/conf.d/ 2>/dev/null' \
    "httpd is configured to listen on port 8080" \
    "httpd is not configured for port 8080"

# Check port 8080 is listening
check 'ss -tlnp | grep -q ":8080"' \
    "Port 8080 is listening" \
    "Port 8080 is not listening"

# Check SELinux allows httpd on 8080
check 'semanage port -l 2>/dev/null | grep http | grep -q 8080' \
    "SELinux allows httpd on port 8080" \
    "SELinux may not allow httpd on 8080"
