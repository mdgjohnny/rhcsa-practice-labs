#!/usr/bin/env bash
# Task: Create user70 with UID 7000, comment "I am user70", and maximum 30 days account inactivity.
# Title: Create User with Attributes
# Category: users-groups

check 'id user70 &>/dev/null' \
    "User user70 exists" \
    "User user70 does not exist"

check '[[ $(id -u user70 2>/dev/null) -eq 7000 ]]' \
    "User user70 has UID 7000" \
    "User user70 does not have UID 7000"

check 'getent passwd user70 | grep -q "I am user70"' \
    "User user70 has correct comment" \
    "User user70 comment is incorrect"

check '[[ $(awk -F: "/^user70:/{print \$7}" /etc/shadow) -eq 30 ]]' \
    "User user70 inactivity set to 30 days" \
    "User user70 inactivity not set to 30 days"
