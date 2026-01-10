#!/usr/bin/env bash
# Task: Create directory for group100 (with user100, user200). Set sticky bit to prevent deletion of others' files.
# Title: Create Collaborative Directory
# Category: file-systems
# Target: node1

check '[[ -d /shared ]]' \
    "Directory /shared exists" \
    "Directory /shared does not exist"

check 'getent group group100 &>/dev/null' \
    "Group group100 exists" \
    "Group group100 does not exist"

check 'stat -c %G /shared | grep -q group100' \
    "/shared is group-owned by group100" \
    "/shared is not group-owned by group100"

check 'stat -c %a /shared | grep -q "^1...\|^3..."' \
    "/shared has sticky bit set" \
    "/shared does not have sticky bit set"

check 'id -nG user100 | grep -q group100' \
    "user100 is member of group100" \
    "user100 is not member of group100"

check 'id -nG user200 | grep -q group100' \
    "user200 is member of group100" \
    "user200 is not member of group100"
