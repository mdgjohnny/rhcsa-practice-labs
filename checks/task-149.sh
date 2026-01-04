#!/usr/bin/env bash
# Task: Change group membership on /mnt/mnt1 to group10. Set read/write/execute permissions on /mnt/mnt1 for group members and revoke all permissions for public
# Category: users-groups
# Target: node1

# Check directory exists
check '[[ -d /mnt/mnt1 ]]' \
    "Directory /mnt/mnt1 exists" \
    "Directory /mnt/mnt1 does not exist"

# Check group ownership
check 'stat -c %G /mnt/mnt1 2>/dev/null | grep -q "group10"' \
    "/mnt/mnt1 is owned by group10" \
    "/mnt/mnt1 is not owned by group10"

# Check group has rwx permissions
PERMS=$(stat -c %a /mnt/mnt1 2>/dev/null)
check '[[ "${PERMS:1:1}" == "7" ]]' \
    "Group has rwx permissions on /mnt/mnt1" \
    "Group does not have rwx on /mnt/mnt1"

# Check others have no permissions
check '[[ "${PERMS:2:1}" == "0" ]]' \
    "Others have no permissions on /mnt/mnt1" \
    "Others have permissions on /mnt/mnt1"
