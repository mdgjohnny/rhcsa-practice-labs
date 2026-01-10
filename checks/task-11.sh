#!/usr/bin/env bash
# Task: Create users edwin and santos in group "dbadmin", and serene and alex in group "accounting". User santos must have UID 1234 and no login shell.
# Title: Create Users and Groups
# Category: users-groups
# Target: node1

check 'id edwin &>/dev/null' \
    "User edwin exists" \
    "User edwin does not exist"

check 'id santos &>/dev/null' \
    "User santos exists" \
    "User santos does not exist"

check 'id serene &>/dev/null' \
    "User serene exists" \
    "User serene does not exist"

check 'id alex &>/dev/null' \
    "User alex exists" \
    "User alex does not exist"

check 'getent group dbadmin &>/dev/null' \
    "Group dbadmin exists" \
    "Group dbadmin does not exist"

check 'getent group accounting &>/dev/null' \
    "Group accounting exists" \
    "Group accounting does not exist"

check 'id -nG edwin | grep -q dbadmin' \
    "User edwin is member of dbadmin" \
    "User edwin is not member of dbadmin"

check 'id -nG santos | grep -q dbadmin' \
    "User santos is member of dbadmin" \
    "User santos is not member of dbadmin"

check 'id -nG serene | grep -q accounting' \
    "User serene is member of accounting" \
    "User serene is not member of accounting"

check 'id -nG alex | grep -q accounting' \
    "User alex is member of accounting" \
    "User alex is not member of accounting"

check '[[ $(id -u santos) -eq 1234 ]]' \
    "User santos has UID 1234" \
    "User santos does not have UID 1234"

check 'getent passwd santos | grep -qE "nologin|/bin/false"' \
    "User santos has no interactive shell" \
    "User santos has an interactive shell"
