#!/usr/bin/env bash
# Task: Enable atd access for user20, deny for user30
# Title: Configure atd Access
# Category: operate-systems
# Target: node1


check 'systemctl is-active atd &>/dev/null' \
    "Service atd is running" \
    "Service atd is not running"
