#!/usr/bin/env bash
# Task: On rhcsa2 - Add group20, change /mnt/lvfs1 group to group20
# rwx for owner, group, and others

check 'ssh "$NODE2_IP" "getent group group20 &>/dev/null" 2>/dev/null' \
    "Group group20 exists on node2" \
    "Group group20 does not exist on node2"

check 'ssh "$NODE2_IP" "stat -c %G /mnt/lvfs1 | grep -q group20" 2>/dev/null' \
    "/mnt/lvfs1 group is group20 on node2" \
    "/mnt/lvfs1 group is not group20 on node2"

check 'ssh "$NODE2_IP" "stat -c %a /mnt/lvfs1 | grep -q 777" 2>/dev/null' \
    "/mnt/lvfs1 has rwx for all on node2" \
    "/mnt/lvfs1 does not have rwx for all"
