#!/usr/bin/env bash
# Task: Case-insensitive search for "essential" in /usr/share/dict/linux.words
# Output to /var/tmp/pattern.txt, omit empty lines

check '[[ -f /var/tmp/pattern.txt ]]' \
    "File /var/tmp/pattern.txt exists" \
    "File /var/tmp/pattern.txt does not exist"

check 'grep -qi "^essential" /var/tmp/pattern.txt 2>/dev/null' \
    "/var/tmp/pattern.txt contains lines starting with 'essential'" \
    "/var/tmp/pattern.txt does not contain expected pattern"

check '! grep -q "^$" /var/tmp/pattern.txt 2>/dev/null' \
    "/var/tmp/pattern.txt has no empty lines" \
    "/var/tmp/pattern.txt contains empty lines"
