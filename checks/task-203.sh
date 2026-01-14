#!/usr/bin/env bash
# Task: Extract all journal entries with priority "err" or higher (err, crit, alert, emerg) since the last boot. Save to /root/errors.txt. The file should exist even if no errors occurred.
# Title: Filter Journal by Priority Level
# Category: operate-systems
# Target: node1

check '[[ -f /root/errors.txt ]]' \
    "File /root/errors.txt exists" \
    "File not found"

# If there are errors in journal, they should be in the file
check 'journalctl -b -p err --no-pager 2>/dev/null | head -1 | grep -qE "^-- No entries --$|^-- Journal" || [[ -s /root/errors.txt ]]' \
    "File captures available errors" \
    "Errors exist in journal but not in file"
