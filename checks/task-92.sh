#!/usr/bin/env bash
# Task: Ensure root access is available (either via direct login or sudo).
# Title: Verify Root Access Configuration  
# Category: operate-systems
# Target: node1

# Check that root access works via sudo
check 'sudo -n whoami 2>/dev/null | grep -q root || sudo whoami 2>/dev/null | grep -q root' \
    "Root access is available via sudo" \
    "Root access not available"

# Check that we can run privileged commands
check 'sudo id | grep -q "uid=0"' \
    "Can execute commands as root" \
    "Cannot execute commands as root"
