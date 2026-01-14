#!/usr/bin/env bash
# Task: Create group "group10". Create directory /mnt/mnt1 with group ownership set to group10. Group members should have full rwx access, others should have no access at all.
# Title: Configure Group Directory Permissions
# Category: users-groups
# Target: node1

check 'getent group group10 &>/dev/null' \
    "Group group10 exists" \
    "Group group10 does not exist"

check '[[ -d /mnt/mnt1 ]]' \
    "Directory /mnt/mnt1 exists" \
    "Directory /mnt/mnt1 does not exist"

check 'stat -c %G /mnt/mnt1 2>/dev/null | grep -q "group10"' \
    "/mnt/mnt1 is group-owned by group10" \
    "/mnt/mnt1 is not owned by group10"

# Check permissions: group has rwx (7), others have none (0)
check '[[ $(stat -c %a /mnt/mnt1) =~ ^[0-7]70$ ]]' \
    "Group has rwx, others have no access" \
    "Permissions incorrect (need x70 pattern)"
