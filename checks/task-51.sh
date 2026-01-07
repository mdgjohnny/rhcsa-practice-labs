#!/usr/bin/env bash
# Task: Flip the SELinux boolean nfs_export_all_rw persistently
# Title: Set SELinux Boolean
# Category: security

check 'getsebool nfs_export_all_rw | grep -q "on"' \
    "Boolean nfs_export_all_rw is on" \
    "Boolean nfs_export_all_rw is not on"

check 'semanage boolean -l | grep nfs_export_all_rw | grep -q "on.*permanent\|on,.*on"' \
    "nfs_export_all_rw is persistent" \
    "nfs_export_all_rw is not persistent"
