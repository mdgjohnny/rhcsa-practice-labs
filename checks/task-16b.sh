#!/usr/bin/env bash
# Task: Set the default boot target to multi-user.target (non-graphical). System must boot to this target.
# Title: Set Default Boot Target
# Category: deploy-maintain
# Target: node2

check 'systemctl get-default | grep -q "multi-user.target"' \
    "Default target is multi-user.target" \
    "Default target is not multi-user.target (got $(systemctl get-default))"
