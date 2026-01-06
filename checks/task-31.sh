#!/usr/bin/env bash
# Task: Create group30 (GID 3000), add user60/user80
# Category: users-groups
# Create /sdata with setgid, group write, owned by root:group30

check \'run_ssh "$NODE1_IP" "getent group group30" &>/dev/null\' \
    "Group group30 exists" \
    "Group group30 does not exist"

check '[[ $(getent group group30 | cut -d: -f3) -eq 3000 ]]' \
    "Group group30 has GID 3000" \
    "Group group30 does not have GID 3000"

check \'run_ssh "$NODE1_IP" "id user60" &>/dev/null\' \
    "User user60 exists" \
    "User user60 does not exist"

check \'run_ssh "$NODE1_IP" "id user80" &>/dev/null\' \
    "User user80 exists" \
    "User user80 does not exist"

check 'id -nG user60 | grep -q group30' \
    "user60 is member of group30" \
    "user60 is not member of group30"

check 'id -nG user80 | grep -q group30' \
    "user80 is member of group30" \
    "user80 is not member of group30"

check \'run_ssh "$NODE1_IP" "test -d /sdata"\' \
    "Directory /sdata exists" \
    "Directory /sdata does not exist"

check \'run_ssh "$NODE1_IP" "stat -c %U:%G /sdata | grep -q "root:group30""\' \
    "/sdata owned by root:group30" \
    "/sdata not owned by root:group30"

check \'run_ssh "$NODE1_IP" "stat -c %a /sdata | grep -q "^2""\' \
    "/sdata has setgid bit" \
    "/sdata does not have setgid bit"
