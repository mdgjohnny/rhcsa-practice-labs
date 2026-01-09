#!/usr/bin/env bash
# Task: Add group20, change /mnt/lvfs1 group to group20, rwx for all
# Title: Set Directory Group
# Category: file-systems
# Target: node2

check 'getent group group20 &>/dev/null' \
    "Group group20 exists" \
    "Group group20 does not exist"

check 'stat -c %G /mnt/lvfs1 | grep -q group20' \
    "/mnt/lvfs1 group is group20" \
    "/mnt/lvfs1 group is not group20"

check 'stat -c %a /mnt/lvfs1 | grep -q 777' \
    "/mnt/lvfs1 has rwx for all" \
    "/mnt/lvfs1 does not have rwx for all"
