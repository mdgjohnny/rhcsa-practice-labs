#!/usr/bin/env bash
# Task: Configure user20 to use sudo without password prompt. Test with: sudo -u user20 sudo whoami
# Title: Configure Passwordless Sudo
# Category: users-groups
# Target: node1


check 'grep -rq "user20" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \
    "Sudo config for user20 exists" \
    "No sudo config for user20"
