#!/usr/bin/env bash
# Task: Install and enable httpd web server
# Title: Install & Enable httpd
# Category: deploy-maintain
# Target: node1

# Check if httpd or nginx is installed
check 'rpm -q httpd &>/dev/null || rpm -q nginx &>/dev/null' \
    "Web server package is installed" \
    "No web server package installed"

# Check if web server service is running
check 'systemctl is-active httpd &>/dev/null || systemctl is-active nginx &>/dev/null' \
    "Web server is running" \
    "Web server is not running"

# Check if web server is enabled for automatic start
check 'systemctl is-enabled httpd &>/dev/null || systemctl is-enabled nginx &>/dev/null' \
    "Web server is enabled at boot" \
    "Web server is not enabled at boot"
