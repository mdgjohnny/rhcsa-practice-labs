#!/usr/bin/env bash
# Task: Create /root/createfiles.sh that uses a for loop to create files file1.txt through file5.txt in /tmp/testfiles/.
# Title: Shell Script - For Loop File Creation
# Category: shell-scripts
# Target: node1

check '[[ -x /root/createfiles.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "for " /root/createfiles.sh' \
    "Script uses for loop" \
    "No for loop found"

check '/root/createfiles.sh 2>/dev/null; [[ -f /tmp/testfiles/file1.txt ]] && [[ -f /tmp/testfiles/file5.txt ]]' \
    "Script creates file1.txt and file5.txt" \
    "Files not created correctly"
