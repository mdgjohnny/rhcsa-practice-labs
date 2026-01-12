#!/usr/bin/env bash
# Task: Run "find /etc -name '*.conf'" and redirect stdout to /root/conf-files.txt and stderr to /root/conf-errors.txt.
# Title: Redirect stdout and stderr Separately
# Category: essential-tools
# Target: node1

check '[[ -f /root/conf-files.txt ]]' \
    "File /root/conf-files.txt exists" \
    "File /root/conf-files.txt not found"

check '[[ -f /root/conf-errors.txt ]]' \
    "File /root/conf-errors.txt exists" \
    "File /root/conf-errors.txt not found"

check 'grep -q "\.conf" /root/conf-files.txt' \
    "conf-files.txt contains .conf file paths" \
    "conf-files.txt doesn't contain .conf entries"

check '[[ -s /root/conf-errors.txt ]] || [[ ! -s /root/conf-errors.txt ]]' \
    "conf-errors.txt exists (may be empty if no permission errors)" \
    "Error file validation failed"
