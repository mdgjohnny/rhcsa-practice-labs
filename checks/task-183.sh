#!/usr/bin/env bash
# Task: Use a pipeline to count the number of installed RPM packages that contain "lib" in their name. Save just the count number to /root/lib-count.txt.
# Title: Pipeline with grep and wc
# Category: essential-tools
# Target: node1

check '[[ -f /root/lib-count.txt ]]' \
    "File /root/lib-count.txt exists" \
    "File /root/lib-count.txt not found"

check 'grep -qE "^[0-9]+$" /root/lib-count.txt' \
    "File contains only a number" \
    "File should contain only a count number"

check 'actual=$(rpm -qa | grep -i lib | wc -l); file_count=$(cat /root/lib-count.txt | tr -d " "); [[ "$file_count" -gt 50 ]]' \
    "Count is reasonable (>50 lib packages)" \
    "Count seems too low"
