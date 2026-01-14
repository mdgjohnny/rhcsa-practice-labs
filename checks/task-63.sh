#!/usr/bin/env bash
# Task: List all packages in the "Development Tools" group and save the list to /var/tmp/devtools.txt.
# Title: List Package Group Contents
# Category: deploy-maintain
# Target: node1

check '[[ -f /var/tmp/devtools.txt ]]' \
    "File /var/tmp/devtools.txt exists" \
    "File /var/tmp/devtools.txt does not exist"

check '[[ -s /var/tmp/devtools.txt ]]' \
    "File has content" \
    "File is empty"

check 'grep -qiE "gcc|make|binutils|autoconf" /var/tmp/devtools.txt' \
    "File contains development packages" \
    "Expected packages not found in file"
