#!/usr/bin/env bash
# Task: Configure the system to boot into multi-user (text) mode by default.
# Title: Set Default Boot Target
# Category: deploy-maintain
# Target: node1

check 'systemctl get-default | grep -q multi-user' \
    "Default target is multi-user.target" \
    "Default target is not multi-user.target"
