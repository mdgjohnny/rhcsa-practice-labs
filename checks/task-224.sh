#!/usr/bin/env bash
# Task: Configure an indirect automount using autofs. When a user accesses /mnt/autodata/rhcsa2, it should automatically mount rhcsa2:/data using NFSv4.
# Title: Configure Indirect Automount for NFS
# Category: file-systems
# Target: node1

check 'rpm -q autofs &>/dev/null' \
    "autofs package is installed" \
    "autofs package not installed"

check 'systemctl is-active autofs &>/dev/null' \
    "autofs service is running" \
    "autofs service not running"

# Check for indirect map entry
check 'grep -rqE "/mnt/autodata.*auto\." /etc/auto.master /etc/auto.master.d/ 2>/dev/null' \
    "Indirect map configured in auto.master" \
    "No indirect map for /mnt/autodata found"

check 'grep -rqE "rhcsa2.*data|\*.*-fstype=nfs" /etc/auto.* 2>/dev/null' \
    "NFS source configured in auto map" \
    "rhcsa2:/data not found in autofs maps"
