#!/usr/bin/env bash
# Task: After using rd.break, you need to relabel SELinux. Create the file that triggers automatic relabeling on next boot.
# Title: Create SELinux Autorelabel File
# Category: operate-systems
# Target: node1

check '[[ -f /.autorelabel ]]' \
    "/.autorelabel file exists" \
    "/.autorelabel not found"
