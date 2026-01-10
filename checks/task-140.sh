#!/usr/bin/env bash
# Task: Set the default systemd target to multi-user.target. Verify: systemctl get-default
# Title: Set Boot Target
# Category: operate-systems
# Target: node1

# Check default target is multi-user
check 'systemctl get-default | grep -q "multi-user.target"' \
    "Default boot target is multi-user.target" \
    "Default boot target is not multi-user.target"
