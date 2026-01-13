#!/usr/bin/env bash
# Task: A script /opt/scripts/backup.sh needs to write to /backup directory. The script runs via cron. Configure SELinux context on /backup to allow this.
# Title: SELinux Context for Backup Directory
# Category: security
# Target: node1


check '[[ -d /backup ]]' \
    "Directory /backup exists" \
    "Directory /backup does not exist"

check 'ls -Zd /backup 2>/dev/null | grep -qE "backup_store_t|var_t|usr_t"' \
    "/backup has appropriate SELinux context" \
    "/backup does not have appropriate context"

check 'semanage fcontext -l | grep -q "/backup"' \
    "SELinux context rule is persistent" \
    "SELinux context rule not persistent"
