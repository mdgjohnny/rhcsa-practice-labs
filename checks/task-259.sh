#!/usr/bin/env bash
# Task: Create a script /root/emergency-recovery.sh that would run the password reset commands after rd.break (mount sysroot, chroot, passwd, touch autorelabel).
# Title: Create Emergency Recovery Script
# Category: operate-systems
# Target: node1

check '[[ -f /root/emergency-recovery.sh ]]' \
    "Recovery script exists" \
    "Script not found"

check 'grep -qE "mount.*sysroot|mount -o remount" /root/emergency-recovery.sh' \
    "Script remounts sysroot" \
    "sysroot remount not found"

check 'grep -q "chroot" /root/emergency-recovery.sh' \
    "Script uses chroot" \
    "chroot not found"

check 'grep -q "passwd" /root/emergency-recovery.sh' \
    "Script runs passwd" \
    "passwd not found"

check 'grep -q "autorelabel" /root/emergency-recovery.sh' \
    "Script creates autorelabel" \
    "autorelabel not found"
