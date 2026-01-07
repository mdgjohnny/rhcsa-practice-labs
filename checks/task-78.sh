#!/usr/bin/env bash
# Task: Redirect both stdout and stderr of 'ls -al wergihl *' to /tmp/lsoutput
# Title: Redirect stdout/stderr
# Category: essential-tools
# Target: node1

# Check if the output file exists
check '[[ -f /tmp/lsoutput ]]' \
    "File /tmp/lsoutput exists" \
    "File /tmp/lsoutput does not exist"

# Check if it contains error output (wergihl doesn't exist)
check 'grep -q "wergihl\|No such file\|cannot access" /tmp/lsoutput 2>/dev/null' \
    "/tmp/lsoutput contains error messages" \
    "/tmp/lsoutput does not contain expected error output"
