#!/usr/bin/env bash
# Task: Create a script /root/usercheck.sh that accepts a username as an argument. The script should print "User exists" if the user exists on the system, or "User not found" otherwise.
# Title: Shell Script - Check User Exists
# Category: shell-scripts
# Target: node1

check '[[ -f /root/usercheck.sh ]]' \
    "Script /root/usercheck.sh exists" \
    "Script /root/usercheck.sh not found"

check '[[ -x /root/usercheck.sh ]]' \
    "Script is executable" \
    "Script is not executable"

check 'head -1 /root/usercheck.sh | grep -qE "^#!"' \
    "Script has shebang line" \
    "Script missing shebang line"

check 'grep -qE "(if |test |\[\[|\[)" /root/usercheck.sh' \
    "Script uses conditional construct (if/test/[])" \
    "Script missing conditional construct"

check 'grep -qE "\\\$1|\\\${1}" /root/usercheck.sh' \
    "Script uses positional parameter \$1" \
    "Script doesn't use positional parameter"

check '/root/usercheck.sh root 2>/dev/null | grep -qi "exists"' \
    "Script correctly identifies existing user (root)" \
    "Script fails to identify existing user"

check '/root/usercheck.sh nonexistent_user_xyz99 2>/dev/null | grep -qi "not found"' \
    "Script correctly reports non-existent user" \
    "Script fails for non-existent user"
