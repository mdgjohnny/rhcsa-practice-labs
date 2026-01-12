#!/usr/bin/env bash
# Task: Create /root/checkroot.sh that checks if it's run as root. Exit with code 0 if root, exit with code 1 if not root. Print appropriate message.
# Title: Shell Script - Check Root and Exit Codes
# Category: shell-scripts
# Target: node1

check '[[ -x /root/checkroot.sh ]]' \
    "Script /root/checkroot.sh exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "exit [01]" /root/checkroot.sh' \
    "Script uses exit codes" \
    "Script doesn't use exit codes"

check 'grep -qE "\\\$UID|\\\$EUID|id -u|whoami" /root/checkroot.sh' \
    "Script checks for root user" \
    "Script doesn't check user identity"

check '/root/checkroot.sh; [[ $? -eq 0 ]]' \
    "Script exits 0 when run as root" \
    "Script doesn't exit 0 as root"

check 'su - nobody -s /bin/bash -c "/root/checkroot.sh" 2>/dev/null; [[ $? -eq 1 ]]' \
    "Script exits 1 when run as non-root" \
    "Script doesn't exit 1 as non-root"
