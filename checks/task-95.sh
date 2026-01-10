#!/usr/bin/env bash
# Task: Create /groups/livingopensource and /groups/operations with proper group permissions.
# Title: Create Shared Directories
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

# Check group ownership
check 'stat -c %G /groups/livingopensource 2>/dev/null | grep -q "livingopensource"' \
    "/groups/livingopensource owned by group livingopensource" \
    "/groups/livingopensource not owned by livingopensource"

check 'stat -c %G /groups/operations 2>/dev/null | grep -q "operations"' \
    "/groups/operations owned by group operations" \
    "/groups/operations not owned by operations"
