#!/usr/bin/env bash
# Task: Create group "sysadmins" with members linda and anna. Grant the group full sudo access.
# Title: Configure Sudo Group
# Category: users-groups
# Target: node1

check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"

check 'id anna &>/dev/null' \
    "User anna exists" \
    "User anna does not exist"

check 'getent group sysadmins &>/dev/null' \
    "Group sysadmins exists" \
    "Group sysadmins does not exist"

check 'grep -qE "^%sysadmins.*ALL.*ALL" /etc/sudoers /etc/sudoers.d/* 2>/dev/null' \
    "sysadmins has sudo ALL access" \
    "sysadmins does not have sudo access"
