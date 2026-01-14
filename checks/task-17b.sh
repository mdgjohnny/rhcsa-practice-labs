#!/usr/bin/env bash
# Task: Configure a direct automount for rhcsa1:/share1 to mount automatically at /share2 when accessed. The mount should be configured using autofs.
# Title: Configure Direct Automount for NFS Share
# Category: file-systems
# Target: node2

check 'rpm -q autofs &>/dev/null' \
    "autofs package is installed" \
    "autofs package not installed"

check 'systemctl is-active autofs &>/dev/null' \
    "autofs service is running" \
    "autofs service not running"

check 'grep -rq "share2" /etc/auto.* 2>/dev/null' \
    "share2 configured in autofs maps" \
    "share2 not found in autofs configuration"

check 'grep -rqE "rhcsa1.*share1|share1.*rhcsa1" /etc/auto.* 2>/dev/null' \
    "rhcsa1:/share1 source configured" \
    "rhcsa1:/share1 not found in autofs maps"
