#!/usr/bin/env bash
# Task: Install Apache httpd and configure it to start automatically at boot. Ensure the service is running.
# Title: Install and Enable httpd
# Category: deploy-maintain
# Target: node1

check 'rpm -q httpd &>/dev/null' \
    "Package httpd is installed" \
    "Package httpd is not installed"

check 'systemctl is-enabled httpd 2>/dev/null | grep -q enabled' \
    "Service httpd is enabled at boot" \
    "Service httpd is not enabled at boot"

check 'systemctl is-active httpd 2>/dev/null | grep -q active' \
    "Service httpd is running" \
    "Service httpd is not running"
