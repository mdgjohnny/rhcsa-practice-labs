#!/usr/bin/env bash
# Task: Create /groups/livingopensource and /groups/operations. Set group ownership to matching groups.
# Title: Create Group Directories
# Category: file-systems
# Target: node1

check '[[ -d /groups/livingopensource ]]' \
    "Directory /groups/livingopensource exists" \
    "Directory /groups/livingopensource does not exist"

check '[[ -d /groups/operations ]]' \
    "Directory /groups/operations exists" \
    "Directory /groups/operations does not exist"

# Check group ownership
check 'stat -c %G /groups/livingopensource 2>/dev/null | grep -q "livingopensource"' \
    "/groups/livingopensource owned by group livingopensource" \
    "/groups/livingopensource not owned by livingopensource"

check 'stat -c %G /groups/operations 2>/dev/null | grep -q "operations"' \
    "/groups/operations owned by group operations" \
    "/groups/operations not owned by operations"
