#!/usr/bin/env bash
# Task: Set GRUB bootloader timeout to 2 seconds.
# Title: Set Bootloader Timeout
# Category: deploy-maintain
# Target: node2

check 'grep -q "GRUB_TIMEOUT=2" /etc/default/grub' \
    "GRUB timeout set to 2 seconds" \
    "GRUB timeout not set to 2 seconds"
