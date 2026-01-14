#!/usr/bin/env bash
# Task: Inspect the ubi8 image and find its total size. Save the size (with units like MB or bytes) to /root/image-size.txt.
# Title: Inspect Image Size
# Category: containers
# Target: node1

check '[[ -f /root/image-size.txt ]]' \
    "File /root/image-size.txt exists" \
    "File not found"

check '[[ -s /root/image-size.txt ]]' \
    "File has content" \
    "File is empty"

check 'grep -qE "[0-9]+(MB|GB|B|M|G|bytes)" /root/image-size.txt || grep -qE "^[0-9]+$" /root/image-size.txt' \
    "File contains size information" \
    "No valid size information found"
