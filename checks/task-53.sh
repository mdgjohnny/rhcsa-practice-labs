#!/usr/bin/env bash
# Task: On rhcsa2 - Set bootloader timeout to 2 seconds

check 'ssh "$NODE2_IP" "grep -q \"GRUB_TIMEOUT=2\" /etc/default/grub" 2>/dev/null' \
    "GRUB timeout set to 2 seconds on node2" \
    "GRUB timeout not set to 2 seconds"
