#!/usr/bin/env bash
# Task: Perform a case-insensitive search for all lines in the /usr/share/dict/linux.words file that begin with the pattern "essential" Redirect the output to /var/tmp/pattern.txt file. Make sure that empty lines are omitted
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
