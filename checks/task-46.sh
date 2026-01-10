#!/usr/bin/env bash
# Task: Enable atd service access for user20, deny access for user30.
# Title: Configure atd Access
# Category: deploy-maintain
# Target: node2

check 'grep -q user20 /etc/at.allow 2>/dev/null' \
    "user20 is in /etc/at.allow" \
    "user20 is not in /etc/at.allow"

check 'grep -q user30 /etc/at.deny 2>/dev/null' \
    "user30 is in /etc/at.deny" \
    "user30 is not in /etc/at.deny"
