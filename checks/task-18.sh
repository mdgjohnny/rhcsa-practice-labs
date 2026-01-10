#!/usr/bin/env bash
# Task: Search for "essential" (case-insensitive) in /usr/share/dict/linux.words. Save to /var/tmp/pattern.txt
# Title: Search Files with grep
# Category: essential-tools

check '[[ -f /var/tmp/pattern.txt ]]' \
    "File /var/tmp/pattern.txt exists" \
    "File /var/tmp/pattern.txt does not exist"

check 'grep -qi "^essential" /var/tmp/pattern.txt 2>/dev/null' \
    "/var/tmp/pattern.txt contains lines starting with 'essential'" \
    "/var/tmp/pattern.txt does not contain expected pattern"

check '! grep -q "^$" /var/tmp/pattern.txt 2>/dev/null' \
    "/var/tmp/pattern.txt has no empty lines" \
    "/var/tmp/pattern.txt contains empty lines"
