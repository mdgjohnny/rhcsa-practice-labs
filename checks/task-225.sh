#!/usr/bin/env bash
# Task: Configure autofs to mount the NFS share rhcsa2:/export/data on-demand at /autodata. The mount should only activate when accessed.
# Title: Configure Autofs Direct Mount
# Category: file-systems
# Target: node1

check 'systemctl is-active autofs &>/dev/null' \
    "autofs service is running" \
    "autofs service not running"

check 'grep -rq "autodata" /etc/auto.master /etc/auto.master.d/ 2>/dev/null' \
    "autodata mount point configured in auto.master" \
    "autodata not found in auto.master"
