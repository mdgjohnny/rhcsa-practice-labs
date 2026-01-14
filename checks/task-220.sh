#!/usr/bin/env bash
# Task: The vsftpd FTP server is running and users can log in, but they cannot upload files to /var/ftp/uploads/ despite correct file permissions (777). The issue is SELinux. Diagnose and fix it so FTP users can write to this directory. The fix must persist across reboots.
# Title: Troubleshoot FTP Upload Access (SELinux)
# Category: security
# Target: node1

# Self-contained setup
if ! rpm -q vsftpd &>/dev/null; then
    dnf install -y vsftpd &>/dev/null
fi

# Create uploads directory
mkdir -p /var/ftp/uploads
chmod 777 /var/ftp/uploads

# Configure vsftpd for anonymous uploads
cat > /etc/vsftpd/vsftpd.conf << 'VSFTPD'
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
anon_root=/var/ftp
listen=YES
listen_ipv6=NO
pam_service_name=vsftpd
VSFTPD

# Ensure vsftpd is running
systemctl enable vsftpd &>/dev/null
systemctl restart vsftpd &>/dev/null

# THE CHECKS - test actual FTP upload capability
check 'echo "test" | timeout 5 curl -s -T - ftp://127.0.0.1/uploads/testfile.txt --user anonymous:test@test.com 2>/dev/null && [[ -f /var/ftp/uploads/testfile.txt ]]' \
    "FTP upload to /var/ftp/uploads/ succeeds" \
    "FTP upload failing (hint: check audit.log for ftpd AVC denials)"

check 'getsebool ftpd_full_access 2>/dev/null | grep -q " on$"' \
    "Correct SELinux boolean is enabled" \
    "Required SELinux boolean is not enabled"

check 'semanage boolean -l 2>/dev/null | grep "ftpd_full_access " | grep -qE "\(on[[:space:]]*,[[:space:]]*on\)"' \
    "Boolean is configured persistently" \
    "Boolean may not survive reboot (did you use -P?)"
