#!/usr/bin/env bash
# Task: Set COLOR=red environment variable for all subshells
# Title: Environment Variable (COLOR)
# Category: essential-tools
# Target: node1

# Check if COLOR variable is exported in profile files
check 'grep -rq "export COLOR=red" /etc/profile /etc/profile.d/ ~/.bashrc ~/.bash_profile 2>/dev/null' \
    "COLOR=red is exported in shell profile" \
    "COLOR=red export not found in profile files"

# Check if subshell inherits the variable
check 'bash -c "echo \$COLOR" | grep -q "red"' \
    "Subshell inherits COLOR=red" \
    "Subshell does not have COLOR=red"
