#!/usr/bin/env bash
# Task: Create /root/default.sh that takes an optional argument. If no argument given, use "default" as the value. Print the value.
# Title: Shell Script - Default Parameter Value
# Category: shell-scripts
# Target: node1

check '[[ -x /root/default.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check '/root/default.sh 2>/dev/null | grep -qi "default"' \
    "Script uses default value when no argument" \
    "Default value not used"

check '/root/default.sh custom 2>/dev/null | grep -qi "custom"' \
    "Script uses provided argument" \
    "Provided argument not used"
