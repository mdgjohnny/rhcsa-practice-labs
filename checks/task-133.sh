#!/usr/bin/env bash
# Task: Find all files with the SetUID permission bit set on the system. Save the complete list of file paths to /root/suidfiles.
# Title: Find SetUID Files
# Category: users-groups
# Target: node1

check '[[ -f /root/suidfiles ]]' \
    "File /root/suidfiles exists" \
    "File /root/suidfiles does not exist"

# Must contain common SUID files
check 'grep -q "/usr/bin/passwd" /root/suidfiles 2>/dev/null' \
    "List includes /usr/bin/passwd" \
    "/usr/bin/passwd not in list (common SUID file)"

check 'grep -q "/usr/bin/sudo" /root/suidfiles 2>/dev/null || grep -q "/bin/su" /root/suidfiles 2>/dev/null' \
    "List includes sudo or su" \
    "sudo/su not in list"

# Verify it's actually a list of SUID files, not random content
check '[[ $(wc -l < /root/suidfiles) -ge 5 ]]' \
    "List contains multiple entries" \
    "List seems incomplete (should have many SUID files)"
