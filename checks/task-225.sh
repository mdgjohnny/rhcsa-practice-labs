#!/usr/bin/env bash
# Task: Configure autofs with a wildcard map: any subdirectory under /exports/auto should mount the corresponding NFS share from rhcsa2. For example, accessing /exports/auto/data should mount rhcsa2:/data.
# Title: Configure Autofs Wildcard Mount
# Category: file-systems
# Target: node1

check 'rpm -q autofs &>/dev/null' \
    "autofs package is installed" \
    "autofs package not installed"

check 'systemctl is-active autofs &>/dev/null' \
    "autofs service is running" \
    "autofs service not running"

check 'grep -rqE "/exports/auto" /etc/auto.master /etc/auto.master.d/ 2>/dev/null' \
    "/exports/auto configured in auto.master" \
    "/exports/auto not in auto.master"

# Check for wildcard (*) in the map file
check 'grep -rqE "^\s*\*\s+-" /etc/auto.* 2>/dev/null | grep -v auto.master' \
    "Wildcard map entry found" \
    "No wildcard (*) map entry found"
