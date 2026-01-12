#!/usr/bin/env bash
# Task: Install development packages (gcc, make). Save package info to /var/tmp/systemtools.out
# Title: Install Development Packages
# Category: deploy-maintain
# Target: node1

# Check for key development tools (gcc and make are essential)
check 'rpm -q gcc &>/dev/null' \
    "gcc is installed" \
    "gcc is not installed"

check 'rpm -q make &>/dev/null' \
    "make is installed" \
    "make is not installed"

check '[[ -f /var/tmp/systemtools.out ]]' \
    "File /var/tmp/systemtools.out exists" \
    "File /var/tmp/systemtools.out does not exist"
