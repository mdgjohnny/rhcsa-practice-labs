#!/usr/bin/env bash
# Task: Create /groups/dbadmin and /groups/accounting as collaborative directories. Ensure files created in these directories are automatically owned by the directory's group, and that only group members can access the contents.
# Title: Create Collaborative Group Directories
# Category: file-systems
# Target: node1

check '[[ -d /groups/dbadmin ]]' \
    "Directory /groups/dbadmin exists" \
    "Directory /groups/dbadmin does not exist"

check '[[ -d /groups/accounting ]]' \
    "Directory /groups/accounting exists" \
    "Directory /groups/accounting does not exist"

check 'stat -c %G /groups/dbadmin | grep -q dbadmin' \
    "/groups/dbadmin is group-owned by dbadmin" \
    "/groups/dbadmin is not group-owned by dbadmin"

check 'stat -c %G /groups/accounting | grep -q accounting' \
    "/groups/accounting is group-owned by accounting" \
    "/groups/accounting is not group-owned by accounting"

check '[[ $(stat -c %a /groups/dbadmin) =~ ^2[0-7][0-7]0$ ]]' \
    "/groups/dbadmin has setgid and no other access" \
    "/groups/dbadmin needs setgid bit and no access for others"

check '[[ $(stat -c %a /groups/accounting) =~ ^2[0-7][0-7]0$ ]]' \
    "/groups/accounting has setgid and no other access" \
    "/groups/accounting needs setgid bit and no access for others"
