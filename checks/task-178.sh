#!/usr/bin/env bash
# Task: Create user "developer" with password "devpass". Then using that account, create a file /tmp/developer-was-here containing "Hello from developer" (the file must be owned by developer).
# Title: Switch Users and Create File
# Category: essential-tools
# Target: node1

check 'id developer &>/dev/null' \
    "User developer exists" \
    "User developer not found"

check '[[ -f /tmp/developer-was-here ]]' \
    "File /tmp/developer-was-here exists" \
    "File /tmp/developer-was-here not found"

check 'stat -c %U /tmp/developer-was-here 2>/dev/null | grep -q developer' \
    "File is owned by developer" \
    "File is not owned by developer (must su to developer to create)"

check 'grep -q "Hello from developer" /tmp/developer-was-here' \
    "File contains correct content" \
    "File doesn't contain expected content"
