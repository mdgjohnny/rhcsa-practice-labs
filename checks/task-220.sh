#!/usr/bin/env bash
# Task: The vsftpd FTP server is running and users can log in, but they cannot upload files to /var/ftp/uploads/ despite correct file permissions (777). The issue is SELinux. Diagnose and fix it so FTP users can write to this directory. The fix must persist across reboots.
# Title: Troubleshoot FTP Upload Access (SELinux)
# Category: security
# Target: node1

check 'echo "test" | timeout 5 curl -s -T - ftp://127.0.0.1/uploads/testfile.txt --user anonymous:test@test.com 2>/dev/null && [[ -f /var/ftp/uploads/testfile.txt ]]' \
    "FTP upload to /var/ftp/uploads/ succeeds" \
    "FTP upload failing (hint: check audit.log for ftpd AVC denials)"

check 'getsebool ftpd_full_access 2>/dev/null | grep -q " on$"' \
    "Correct SELinux boolean is enabled" \
    "Required SELinux boolean is not enabled"

check 'semanage boolean -l 2>/dev/null | grep "ftpd_full_access " | grep -qE "\(on[[:space:]]*,[[:space:]]*on\)"' \
    "Boolean is configured persistently" \
    "Boolean may not survive reboot (did you use -P?)"
