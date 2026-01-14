#!/usr/bin/env bash
# Task: Create groups "livingopensource" and "operations". Create /groups/livingopensource and /groups/operations directories with: group ownership matching directory name, SGID bit set, and sticky bit so only file owners can delete their files.
# Title: Create Shared Directories with Sticky Bit
# Category: users-groups
# Target: node1

check 'getent group livingopensource &>/dev/null' \
    "Group livingopensource exists" \
    "Group livingopensource does not exist"

check 'getent group operations &>/dev/null' \
    "Group operations exists" \
    "Group operations does not exist"

check '[[ -d /groups/livingopensource ]]' \
    "Directory /groups/livingopensource exists" \
    "Directory /groups/livingopensource does not exist"

check '[[ -d /groups/operations ]]' \
    "Directory /groups/operations exists" \
    "Directory /groups/operations does not exist"

check 'stat -c %G /groups/livingopensource | grep -q "livingopensource"' \
    "/groups/livingopensource owned by group livingopensource" \
    "/groups/livingopensource wrong group"

check 'stat -c %G /groups/operations | grep -q "operations"' \
    "/groups/operations owned by group operations" \
    "/groups/operations wrong group"

# Check for SGID (2xxx or 3xxx) and sticky (1xxx or 3xxx)  
check '[[ $(stat -c %a /groups/livingopensource) =~ ^3[0-7]{3}$ ]]' \
    "/groups/livingopensource has SGID and sticky bit" \
    "/groups/livingopensource needs both SGID and sticky bit (e.g., 3770)"

check '[[ $(stat -c %a /groups/operations) =~ ^3[0-7]{3}$ ]]' \
    "/groups/operations has SGID and sticky bit" \
    "/groups/operations needs both SGID and sticky bit (e.g., 3770)"
