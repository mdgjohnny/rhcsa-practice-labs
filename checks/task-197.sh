#!/usr/bin/env bash
# Task: Apache has been configured as a reverse proxy to a backend service on port 8888, but connections are failing. The configuration and backend are correct - this is an SELinux issue. Diagnose the problem and fix it. The fix must persist across reboots.
# Title: Troubleshoot Apache Reverse Proxy (SELinux)
# Category: security
# Target: node1

check 'curl -sf --max-time 3 http://127.0.0.1/backend 2>/dev/null | grep -q "BACKEND_OK"' \
    "Apache successfully proxies to backend service" \
    "Proxy connection failing (hint: check /var/log/audit/audit.log)"

check 'getsebool httpd_can_network_connect 2>/dev/null | grep -q " on$"' \
    "Correct SELinux boolean is enabled" \
    "Required SELinux boolean is not enabled"

check 'semanage boolean -l 2>/dev/null | grep "httpd_can_network_connect " | grep -qE "\(on[[:space:]]*,[[:space:]]*on\)"' \
    "Boolean is configured persistently" \
    "Boolean may not survive reboot (did you use -P?)"
