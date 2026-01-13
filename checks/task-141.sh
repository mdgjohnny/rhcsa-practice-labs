#!/usr/bin/env bash
# Task: Set SELinux to permissive mode persistently. System must boot in permissive mode.
# Title: Set SELinux Mode
# Category: security
# Target: node1


check 'getenforce | grep -qi permissive' \
    "SELinux is currently in permissive mode" \
    "SELinux is not in permissive mode"

check 'grep -qi "^SELINUX=permissive" /etc/selinux/config' \
    "SELinux config set to permissive (persistent)" \
    "SELinux config not set to permissive"
