#!/usr/bin/env bash
# Task: Enable access to the atd service for user20 and deny for user30
# Category: operate-systems
# Target: node1


check 'systemctl is-active atd &>/dev/null' \
    "Service atd is running" \
    "Service atd is not running"
