#!/usr/bin/env bash
# Task: Copy /etc/hosts to /root/hosts.bak. The copied file should retain a context appropriate for /root, not /etc.
# Title: SELinux Context After Copy
# Category: security
# Target: node1


check '[[ -f /root/hosts.bak ]]' \
    "File /root/hosts.bak exists" \
    "File /root/hosts.bak does not exist"

check 'ls -Z /root/hosts.bak 2>/dev/null | grep -q "admin_home_t"' \
    "/root/hosts.bak has correct context for /root" \
    "/root/hosts.bak has wrong context"
