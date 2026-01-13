#!/usr/bin/env bash
# Task: Create /srv/ftpdata directory for an FTP server. Configure SELinux so vsftpd can read files from this directory.
# Title: SELinux Context for FTP Directory
# Category: security
# Target: node1


check '[[ -d /srv/ftpdata ]]' \
    "Directory /srv/ftpdata exists" \
    "Directory /srv/ftpdata does not exist"

check 'ls -Zd /srv/ftpdata 2>/dev/null | grep -q "public_content_t"' \
    "/srv/ftpdata has correct SELinux context" \
    "/srv/ftpdata does not have correct context"

check 'semanage fcontext -l | grep -q "/srv/ftpdata"' \
    "SELinux context rule is persistent" \
    "SELinux context rule not persistent"
