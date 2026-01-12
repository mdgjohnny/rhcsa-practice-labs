#!/usr/bin/env bash
# Task: Create a script /root/countfiles.sh that counts and displays the number of regular files in a directory passed as argument. If no argument given, use current directory.
# Title: Shell Script - Count Files in Directory
# Category: shell-scripts
# Target: node1

check '[[ -f /root/countfiles.sh ]]' \
    "Script /root/countfiles.sh exists" \
    "Script /root/countfiles.sh not found"

check '[[ -x /root/countfiles.sh ]]' \
    "Script is executable" \
    "Script is not executable"

check 'head -1 /root/countfiles.sh | grep -qE "^#!"' \
    "Script has shebang line" \
    "Script missing shebang line"

check 'grep -qE "(for |while )" /root/countfiles.sh || grep -qE "find.*-type f|ls.*wc" /root/countfiles.sh' \
    "Script uses loop or file counting command" \
    "Script missing loop or counting logic"

# Create test directory with known number of files
check 'mkdir -p /tmp/testcount && touch /tmp/testcount/f{1..5} && result=$(/root/countfiles.sh /tmp/testcount 2>/dev/null) && [[ "$result" =~ 5 ]]' \
    "Script correctly counts files (5 files = 5)" \
    "Script fails to count files correctly"

check 'mkdir -p /tmp/emptydir && result=$(/root/countfiles.sh /tmp/emptydir 2>/dev/null) && [[ "$result" =~ 0 ]]' \
    "Script handles empty directory (returns 0)" \
    "Script fails for empty directory"
