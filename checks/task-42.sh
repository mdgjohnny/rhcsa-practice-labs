#!/usr/bin/env bash
# Task: Create group sysadmins, add linda and anna
# Category: users-groups
# Members can run all admin commands via sudo

check \'run_ssh "$NODE1_IP" "getent group sysadmins" &>/dev/null\' \
    "Group sysadmins exists" \
    "Group sysadmins does not exist"

check \'run_ssh "$NODE1_IP" "id linda" &>/dev/null\' \
    "User linda exists" \
    "User linda does not exist"

check \'run_ssh "$NODE1_IP" "id anna" &>/dev/null\' \
    "User anna exists" \
    "User anna does not exist"

check 'id -nG linda | grep -q sysadmins' \
    "linda is member of sysadmins" \
    "linda is not member of sysadmins"

check 'id -nG anna | grep -q sysadmins' \
    "anna is member of sysadmins" \
    "anna is not member of sysadmins"

check \'run_ssh "$NODE1_IP" "grep -rq "%sysadmins.*ALL=(ALL).*ALL" /etc/sudoers /etc/sudoers.d/ 2>/dev/null"\' \
    "sysadmins group has sudo ALL access" \
    "sysadmins group does not have sudo ALL access"
