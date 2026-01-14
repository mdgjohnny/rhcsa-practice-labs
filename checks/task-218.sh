#!/usr/bin/env bash
# Task: A user "webdev" has created content in their ~/public_html directory, and Apache is configured with UserDir enabled. However, accessing http://localhost/~webdev/ returns a 403 Forbidden error. The file permissions are correct (checked with ls -la). Diagnose and fix the SELinux issue. The fix must persist across reboots.
# Title: Troubleshoot Apache UserDir Access (SELinux)
# Category: security
# Target: node1

check 'curl -sf --max-time 3 http://127.0.0.1/~webdev/ 2>/dev/null | grep -q "USERDIR_WORKS"' \
    "Apache successfully serves user home directory content" \
    "UserDir access failing - 403 Forbidden (hint: check audit.log for AVC denials)"

check 'getsebool httpd_enable_homedirs 2>/dev/null | grep -q " on$"' \
    "Correct SELinux boolean is enabled" \
    "Required SELinux boolean is not enabled"

check 'semanage boolean -l 2>/dev/null | grep "httpd_enable_homedirs " | grep -qE "\(on[[:space:]]*,[[:space:]]*on\)"' \
    "Boolean is configured persistently" \
    "Boolean may not survive reboot (did you use -P?)"
