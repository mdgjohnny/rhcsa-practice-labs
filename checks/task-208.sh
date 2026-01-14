#!/usr/bin/env bash
# Task: A developer copied a file from their home directory to /var/www/html/index.html but Apache returns 403 Forbidden. The file permissions are correct (644). Fix the issue so Apache can serve the file.
# Title: Fix Web Content SELinux Context
# Category: security
# Target: node1

# Setup: Create file with wrong context ONLY if it doesn't exist
if ! rpm -q httpd &>/dev/null; then
    dnf install -y httpd &>/dev/null
fi
mkdir -p /var/www/html
systemctl start httpd &>/dev/null

if [[ ! -f /var/www/html/index.html ]]; then
    echo "<html><body>SELINUX_CONTEXT_OK</body></html>" > /var/www/html/index.html
    chcon -t user_home_t /var/www/html/index.html  # Wrong context
    chmod 644 /var/www/html/index.html
fi

check 'curl -sf http://127.0.0.1/index.html 2>/dev/null | grep -q "SELINUX_CONTEXT_OK"' \
    "Apache can serve /var/www/html/index.html" \
    "Apache returns 403 Forbidden (hint: ls -Z to check context)"

check 'ls -Z /var/www/html/index.html 2>/dev/null | grep -q "httpd_sys_content_t"' \
    "File has correct SELinux context" \
    "File context needs to be fixed (hint: restorecon)"
