#!/usr/bin/env bash
# Task: Set default boot target to multi-user.target on node2
# Title: Set Boot Target (node2)
# Category: deploy-maintain
# Target: node2

check 'systemctl get-default | grep -q "multi-user.target"' \
    "Default target is multi-user.target" \
    "Default target is not multi-user.target (got $(systemctl get-default))"
