#!/usr/bin/env bash
# Task: From your home directory, type the command `ls -al wergihl *` and ensure that errors as well as regular output are redirected to a file with the name `/tmp/lsoutput`
# Category: essential-tools
# Target: node1

# Check if the output file exists
check \'run_ssh "$NODE1_IP" "test -f /tmp/lsoutput"\' \
    "File /tmp/lsoutput exists" \
    "File /tmp/lsoutput does not exist"

# Check if it contains error output (wergihl doesn't exist)
check \'run_ssh "$NODE1_IP" "grep -q "wergihl\|No such file\|cannot access" /tmp/lsoutput 2>/dev/null"\' \
    "/tmp/lsoutput contains error messages" \
    "/tmp/lsoutput does not contain expected error output"
