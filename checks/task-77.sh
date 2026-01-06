#!/usr/bin/env bash
# Task: Modify your shell environment so that on every subshell that is started, a variable is set. The name of the variable should be COLOR, and the value should be set to red. Verify that it is working
# Category: essential-tools
# Target: node1

# Check if COLOR variable is exported in profile files
check \'run_ssh "$NODE1_IP" "grep -rq "export COLOR=red" /etc/profile /etc/profile.d/ ~/.bashrc ~/.bash_profile 2>/dev/null"\' \
    "COLOR=red is exported in shell profile" \
    "COLOR=red export not found in profile files"

# Check if subshell inherits the variable
check 'bash -c "echo \$COLOR" | grep -q "red"' \
    "Subshell inherits COLOR=red" \
    "Subshell does not have COLOR=red"
