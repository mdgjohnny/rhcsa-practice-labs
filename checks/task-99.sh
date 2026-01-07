#!/usr/bin/env bash
# Task: Create Stratis volume on new 10GiB disk, mount persistently
# Title: Stratis Volume on New Disk
# Category: local-storage
# Target: node1

# Check if stratisd service is running
check 'systemctl is-active stratisd &>/dev/null' \
    "Stratis daemon is running" \
    "Stratis daemon is not running"

# Check if a Stratis pool exists
check 'stratis pool list 2>/dev/null | grep -q .' \
    "Stratis pool exists" \
    "No Stratis pool found"

# Check if a Stratis filesystem exists
check 'stratis filesystem list 2>/dev/null | grep -q .' \
    "Stratis filesystem exists" \
    "No Stratis filesystem found"

# Check if mounted persistently (in fstab with stratis fstype)
check 'grep -q "stratis" /etc/fstab' \
    "Stratis mount is in /etc/fstab" \
    "Stratis mount not in /etc/fstab"
