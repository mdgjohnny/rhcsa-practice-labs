#!/usr/bin/env bash
# Task: Install "Development Tools" package group. Capture package info to /var/tmp/systemtools.out
# Title: Install Package Group
# Category: deploy-maintain
# Target: node1

check 'dnf group list installed 2>/dev/null | grep -qi "development tools"' \
    "Development Tools group is installed" \
    "Development Tools group is not installed"

check '[[ -f /var/tmp/systemtools.out ]]' \
    "File /var/tmp/systemtools.out exists" \
    "File /var/tmp/systemtools.out does not exist"
