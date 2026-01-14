#!/usr/bin/env bash
# Task: Your organization requires Apache to proxy requests to backend application servers. By default, SELinux prevents httpd from initiating network connections. Find and enable the boolean that allows httpd to connect to network services. The change must persist across reboots.
# Title: Fix Apache Network Connectivity (SELinux)
# Category: security
# Target: node1

check 'getsebool httpd_can_network_connect 2>/dev/null | grep -q "on"' \
    "httpd_can_network_connect is enabled" \
    "httpd_can_network_connect is not enabled"

check 'semanage boolean -l 2>/dev/null | grep httpd_can_network_connect | grep -q "on.*permanent" || getsebool httpd_can_network_connect 2>/dev/null | grep -q "on"' \
    "Boolean is set persistently" \
    "Boolean may not be persistent"
