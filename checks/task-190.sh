#!/usr/bin/env bash
# Task: Create /opt/shared.sh script. Set permissions so owner can read/write/execute, group can read/execute, others can only execute.
# Title: Set Permissions with Symbolic Mode
# Category: essential-tools
# Target: node1

check '[[ -f /opt/shared.sh ]]' \
    "File /opt/shared.sh exists" \
    "File /opt/shared.sh not found"

check '[[ $(stat -c %a /opt/shared.sh) == "751" ]]' \
    "Permissions are 751 (rwxr-x--x)" \
    "Permissions are not 751"
