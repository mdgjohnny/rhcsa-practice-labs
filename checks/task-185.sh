#!/usr/bin/env bash
# Task: List the SELinux context of the /var/www/html directory and save it to /root/selinux-context.txt. Include the type field (e.g., httpd_sys_content_t).
# Title: List SELinux File Context
# Category: security
# Target: node1

check '[[ -f /root/selinux-context.txt ]]' \
    "File /root/selinux-context.txt exists" \
    "File /root/selinux-context.txt not found"

check 'grep -qE "_t" /root/selinux-context.txt' \
    "File contains SELinux type context" \
    "No SELinux type context found (should end in _t)"

check 'mkdir -p /var/www/html 2>/dev/null; grep -qE "httpd|default_t|html" /root/selinux-context.txt' \
    "Context relates to /var/www/html" \
    "Context doesn't appear correct for /var/www/html"
