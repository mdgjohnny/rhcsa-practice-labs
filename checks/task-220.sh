#!/usr/bin/env bash
# Task: The vsftpd FTP server is running and users can log in, but they cannot upload files to /var/ftp/uploads/ despite correct file permissions (777). Diagnose and fix the issue so FTP users can write to this directory. The fix must persist across reboots.
# Title: Troubleshoot FTP Upload Access
# Category: security
# Target: node1

check 'echo "test" | timeout 5 curl -s -T - ftp://127.0.0.1/uploads/testfile.txt --user anonymous:test@test.com 2>/dev/null && [[ -f /var/ftp/uploads/testfile.txt ]]' \
    "FTP upload to /var/ftp/uploads/ succeeds" \
    "FTP upload failing (check /var/log/audit/audit.log for clues)"

check 'getsebool ftpd_full_access 2>/dev/null | grep -q " on$"' \
    "Correct security setting is enabled" \
    "Required security setting is not enabled"

check 'semanage boolean -l 2>/dev/null | grep "ftpd_full_access " | grep -qE "\(on[[:space:]]*,[[:space:]]*on\)"' \
    "Setting is configured persistently" \
    "Setting may not survive reboot"
