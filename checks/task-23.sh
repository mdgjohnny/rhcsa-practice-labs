#!/usr/bin/env bash
# Task: group100 (user100, user200) collaborates on /shared with sticky bit (no delete others' files)
# Category: file-systems

check \'run_ssh "$NODE1_IP" "test -d /shared"\' \
    "Directory /shared exists" \
    "Directory /shared does not exist"

check \'run_ssh "$NODE1_IP" "getent group group100" &>/dev/null\' \
    "Group group100 exists" \
    "Group group100 does not exist"

check \'run_ssh "$NODE1_IP" "stat -c %G /shared | grep -q group100"\' \
    "/shared is group-owned by group100" \
    "/shared is not group-owned by group100"

check \'run_ssh "$NODE1_IP" "stat -c %a /shared | grep -q "^1...\|^3...""\' \
    "/shared has sticky bit set" \
    "/shared does not have sticky bit set"

check 'id -nG user100 | grep -q group100' \
    "user100 is member of group100" \
    "user100 is not member of group100"

check 'id -nG user200 | grep -q group100' \
    "user200 is member of group100" \
    "user200 is not member of group100"
