#!/usr/bin/env bash
# Task: Inspect a container image and find its total size. Save the size to /root/image-size.txt.
# Title: Inspect Image Size
# Category: containers
# Target: node1

check '[[ -f /root/image-size.txt ]]' \
    "File /root/image-size.txt exists" \
    "File not found"

check 'grep -qE "[0-9]+(MB|GB|B|M|G)" /root/image-size.txt || grep -qE "^[0-9]+" /root/image-size.txt' \
    "File contains size information" \
    "No size information found"
