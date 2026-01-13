#!/usr/bin/env bash
# Task: Create /var/log/myapp directory. Configure SELinux context matching /var/log so applications can write logs there. Make it persistent.
# Title: SELinux Context for Custom Log Directory
# Category: security
# Target: node1


check '[[ -d /var/log/myapp ]]' \
    "Directory /var/log/myapp exists" \
    "Directory /var/log/myapp does not exist"

check 'ls -Zd /var/log/myapp 2>/dev/null | grep -q "var_log_t"' \
    "/var/log/myapp has correct SELinux context" \
    "/var/log/myapp does not have correct context"
