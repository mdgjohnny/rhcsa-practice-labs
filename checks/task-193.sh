#!/usr/bin/env bash
# Task: Create /root/askname.sh that prompts user for their name, reads it, and prints "Welcome, <name>!". Use the read command.
# Title: Shell Script - Read User Input
# Category: shell-scripts
# Target: node1

check '[[ -x /root/askname.sh ]]' \
    "Script /root/askname.sh exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "read " /root/askname.sh' \
    "Script uses read command" \
    "Script doesn't use read command"

check 'grep -qE "Welcome|echo.*\\\$" /root/askname.sh' \
    "Script outputs welcome message with variable" \
    "Script doesn't output welcome with variable"

check 'echo "TestUser" | /root/askname.sh 2>/dev/null | grep -qi "Welcome.*TestUser"' \
    "Script correctly greets user" \
    "Script doesn't greet correctly"
