#!/usr/bin/env bash
# Task: Edit /etc/default/grub to add "rd.break" to GRUB_CMDLINE_LINUX (don't regenerate grub - this is practice only).
# Title: Add rd.break to GRUB Config
# Category: operate-systems
# Target: node1

check 'grep -q "rd.break" /etc/default/grub' \
    "rd.break added to GRUB config" \
    "rd.break not in /etc/default/grub"
