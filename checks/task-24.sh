#!/usr/bin/env bash
# Task: Create user70 with UID 7000, comment "I am user70", max inactivity 30 days
# Category: users-groups

check \'run_ssh "$NODE1_IP" "id user70" &>/dev/null\' \
    "User user70 exists" \
    "User user70 does not exist"

check '[[ $(id -u user70 2>/dev/null) -eq 7000 ]]' \
    "User user70 has UID 7000" \
    "User user70 does not have UID 7000"

check \'run_ssh "$NODE1_IP" "getent passwd user70" | grep -q "I am user70"\' \
    "User user70 has correct comment" \
    "User user70 comment is incorrect"

check \'run_ssh "$NODE1_IP" "chage -l user70 2>/dev/null | grep -q "Password inactive.*30""\' \
    "User user70 inactivity set to 30 days" \
    "User user70 inactivity not set to 30 days"
