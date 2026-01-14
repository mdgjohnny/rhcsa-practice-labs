#!/usr/bin/env bash
# Task: Create users laura and linda as members of group "livingopensource", and users lisa and lori as members of group "operations".
# Title: Create Users with Group Membership
# Category: users-groups
# Target: node1

check 'getent group livingopensource &>/dev/null' \
    "Group livingopensource exists" \
    "Group livingopensource does not exist"

check 'getent group operations &>/dev/null' \
    "Group operations exists" \
    "Group operations does not exist"

check 'id laura &>/dev/null' \
    "User laura exists" \
    "User laura does not exist"

check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"

check 'id lisa &>/dev/null' \
    "User lisa exists" \
    "User lisa does not exist"

check 'id lori &>/dev/null' \
    "User lori exists" \
    "User lori does not exist"

check 'id -nG laura 2>/dev/null | grep -qw livingopensource' \
    "laura is member of livingopensource" \
    "laura is not in livingopensource group"

check 'id -nG linda 2>/dev/null | grep -qw livingopensource' \
    "linda is member of livingopensource" \
    "linda is not in livingopensource group"

check 'id -nG lisa 2>/dev/null | grep -qw operations' \
    "lisa is member of operations" \
    "lisa is not in operations group"

check 'id -nG lori 2>/dev/null | grep -qw operations' \
    "lori is member of operations" \
    "lori is not in operations group"
