#!/usr/bin/env bash
# Task: Create directory /backup and set its SELinux context to backup_store_t. Ensure the context is persistent across relabeling.
# Title: Set SELinux Context for Backup Directory
# Category: security
# Target: node1

check '[[ -d /backup ]]' \
    "Directory /backup exists" \
    "Directory /backup does not exist"

check 'ls -Zd /backup 2>/dev/null | grep -q "backup_store_t"' \
    "/backup has SELinux context backup_store_t" \
    "/backup does not have backup_store_t context"

check 'semanage fcontext -l | grep -qE "/backup.*backup_store_t"' \
    "SELinux context rule is persistent" \
    "SELinux context rule not persistent in semanage"
