#!/usr/bin/env bash
# Task: Create a physical volume on /dev/loop4. Verify it shows in pvs output.
# Title: Create Physical Volume
# Category: local-storage
# Target: node1
# Setup: dd if=/dev/zero of=/tmp/loop4.img bs=1M count=200; losetup /dev/loop4 /tmp/loop4.img

check 'pvs /dev/loop4 &>/dev/null' \
    "Physical volume exists on /dev/loop4" \
    "No physical volume on /dev/loop4 (use pvcreate)"

check 'pvdisplay /dev/loop4 2>/dev/null | grep -q "PV Name"' \
    "Physical volume details available" \
    "Cannot display PV details"
