#!/usr/bin/env bash
# Task: Set SELinux to permissive mode persistently. System must boot in permissive mode.
# Title: Set SELinux Mode
# Category: security
# Target: node1


check 'getenforce | grep -qi permissive' \
    "SELinux is in permissive mode" \
    "SELinux is not in permissive mode"
