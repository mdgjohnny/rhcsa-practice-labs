#!/usr/bin/env bash
# Task: The root password has been lost. A rescue user "sysrescue" (password: rescue123) has sudo access. Use it to reset root's password to "newrootpass".
# Title: Reset Root Password (Simulation)
# Category: operate-systems
# Target: node1
# Setup: useradd sysrescue; echo "sysrescue:rescue123" | chpasswd; echo "sysrescue ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sysrescue

check 'echo "newrootpass" | su - root -c "exit" 2>/dev/null' \
    "Root password is newrootpass" \
    "Root password is not set correctly"
