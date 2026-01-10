#!/usr/bin/env bash
# Task: Configure autofs to automatically mount any subdirectory from the NFS server's /home exports.
# Title: Configure Autofs Wildcard Mount
# Category: networking
# Target: node1

# Check if autofs is installed and running
check 'systemctl is-active autofs &>/dev/null' \
    "autofs service is running" \
    "autofs service is not running"

# Check if auto.master has an entry for home directories
check 'grep -q "/home" /etc/auto.master || grep -qr "/home" /etc/auto.master.d/' \
    "Automount entry for /home exists in auto.master" \
    "No automount entry for /home found"

# Check for wildcard configuration
check 'grep -rq "\*" /etc/auto.home /etc/auto.master.d/ 2>/dev/null || grep -q "\*.*nfs" /etc/auto.* 2>/dev/null' \
    "Wildcard automount is configured" \
    "Wildcard automount not found"
