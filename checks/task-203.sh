#!/usr/bin/env bash
# Task: Extract all journal entries with priority "err" or higher (err, crit, alert, emerg) since boot. Save to /root/errors.txt.
# Title: Filter Journal by Priority
# Category: operate-systems
# Target: node1

check '[[ -f /root/errors.txt ]]' \
    "File /root/errors.txt exists" \
    "File not found"

# Note: File might be empty if no errors
check '[[ -f /root/errors.txt ]]' \
    "Error log file created (may be empty if no errors)" \
    "Error log not created"
