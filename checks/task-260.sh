#!/usr/bin/env bash
# Task: Use setenforce to set SELinux to permissive mode. Verify with getenforce.
# Title: SELinux setenforce Command
# Category: security
# Target: node1

check 'getenforce | grep -qi permissive' \
    "SELinux is permissive" \
    "SELinux not in permissive mode"
