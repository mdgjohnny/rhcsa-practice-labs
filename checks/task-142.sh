#!/usr/bin/env bash
# Task: Search /usr/share/dict/linux.words for lines starting with "essential" (case-insensitive). Save results to /var/tmp/pattern.txt
# Title: Search with grep
# Category: essential-tools
# Target: node1

# Check output file exists
check '[[ -f /var/tmp/pattern.txt ]]' \
    "File /var/tmp/pattern.txt exists" \
    "File /var/tmp/pattern.txt does not exist"

# Check file contains lines starting with "essential" (case insensitive)
check 'grep -qi "^essential" /var/tmp/pattern.txt 2>/dev/null' \
    "/var/tmp/pattern.txt contains essential-related lines" \
    "/var/tmp/pattern.txt does not contain expected content"

# Check no empty lines
check '! grep -q "^$" /var/tmp/pattern.txt 2>/dev/null' \
    "No empty lines in output file" \
    "Output file contains empty lines"
