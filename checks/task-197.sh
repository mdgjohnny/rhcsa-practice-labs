#!/usr/bin/env bash
# Task: Enable the SELinux boolean "httpd_can_network_connect" persistently. This allows Apache to make network connections.
# Title: Enable SELinux Network Boolean
# Category: security
# Target: node1

check 'getsebool httpd_can_network_connect 2>/dev/null | grep -q "on"' \
    "httpd_can_network_connect is enabled" \
    "httpd_can_network_connect is not enabled"

check 'semanage boolean -l 2>/dev/null | grep httpd_can_network_connect | grep -q "on.*permanent" || getsebool httpd_can_network_connect 2>/dev/null | grep -q "on"' \
    "Boolean is set persistently" \
    "Boolean may not be persistent"
