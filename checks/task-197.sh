#!/usr/bin/env bash
# Task: Apache is unable to connect to a remote database server due to SELinux restrictions. Find and enable the appropriate SELinux boolean to allow Apache (httpd) to make outbound network connections. The change must persist across reboots.
# Title: Fix Apache Network Connectivity (SELinux)
# Category: security
# Target: node1

check 'getsebool httpd_can_network_connect 2>/dev/null | grep -q "on"' \
    "httpd_can_network_connect is enabled" \
    "httpd_can_network_connect is not enabled"

check 'semanage boolean -l 2>/dev/null | grep httpd_can_network_connect | grep -q "on.*permanent" || getsebool httpd_can_network_connect 2>/dev/null | grep -q "on"' \
    "Boolean is set persistently" \
    "Boolean may not be persistent"
