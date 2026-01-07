#!/usr/bin/env bash
# Task: Create shared directories /groups/livingopensource and /groups/operations with proper permissions
# Title: Shared Group Directories
# Category: users-groups
# Target: node1

# Check groups exist
check 'getent group livingopensource &>/dev/null' \
    "Group livingopensource exists" \
    "Group livingopensource does not exist"

check 'getent group operations &>/dev/null' \
    "Group operations exists" \
    "Group operations does not exist"

# Check directories exist
check '[[ -d /groups/livingopensource ]]' \
    "Directory /groups/livingopensource exists" \
    "Directory /groups/livingopensource does not exist"

check '[[ -d /groups/operations ]]' \
    "Directory /groups/operations exists" \
    "Directory /groups/operations does not exist"

# Check sticky bit for "delete only own files"
check 'stat -c %a /groups/livingopensource 2>/dev/null | grep -q "1...$\|^1"' \
    "/groups/livingopensource has sticky bit" \
    "/groups/livingopensource missing sticky bit"

check 'stat -c %a /groups/operations 2>/dev/null | grep -q "1...$\|^1"' \
    "/groups/operations has sticky bit" \
    "/groups/operations missing sticky bit"
