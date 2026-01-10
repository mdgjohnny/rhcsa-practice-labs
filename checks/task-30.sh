#!/usr/bin/env bash
# Task: Change group ownership of /mnt/mnt1 to "group10".
# Title: Set Directory Group
# Category: file-systems
# rwx for group, no access for others

check 'stat -c %G /mnt/mnt1 2>/dev/null | grep -q group10' \
    "/mnt/mnt1 group is group10" \
    "/mnt/mnt1 group is not group10"

PERMS=$(stat -c %a /mnt/mnt1 2>/dev/null)
check '[[ "${PERMS:1:1}" == "7" ]]' \
    "/mnt/mnt1 has rwx for group" \
    "/mnt/mnt1 does not have rwx for group"

check '[[ "${PERMS:2:1}" == "0" ]]' \
    "/mnt/mnt1 has no access for others" \
    "/mnt/mnt1 has access for others"
