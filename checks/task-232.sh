#!/usr/bin/env bash
# Task: Pull the ubi8 image if not present, inspect it to find its default working directory, and save that path to /root/ubi8-workdir.txt.
# Title: Inspect Image Working Directory
# Category: containers
# Target: node1

check '[[ -f /root/ubi8-workdir.txt ]]' \
    "File /root/ubi8-workdir.txt exists" \
    "File not found"

check '[[ -s /root/ubi8-workdir.txt ]]' \
    "File has content" \
    "File is empty"

# The working directory should be a path (starts with /)
check 'grep -qE "^/" /root/ubi8-workdir.txt' \
    "File contains a path" \
    "File doesn't contain a valid path"
