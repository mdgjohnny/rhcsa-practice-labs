#!/usr/bin/env bash
# Task: Find all files modified in the last 30 days. Save the list to /var/tmp/modfiles.txt
# Title: Find Recently Modified Files
# Category: essential-tools
# Target: node2

check '[[ -f /var/tmp/modfiles.txt ]]' \
    "File /var/tmp/modfiles.txt exists" \
    "File /var/tmp/modfiles.txt does not exist"

check '[[ -s /var/tmp/modfiles.txt ]]' \
    "/var/tmp/modfiles.txt is not empty" \
    "/var/tmp/modfiles.txt is empty"
