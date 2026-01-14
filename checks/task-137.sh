#!/usr/bin/env bash
# Task: Create user "laura" and grant her full sudo privileges to execute any command as any user without a password.
# Title: Grant Full Sudo Access
# Category: users-groups
# Target: node1

check 'id laura &>/dev/null' \
    "User laura exists" \
    "User laura does not exist"

check 'grep -rqE "laura.*ALL.*ALL|laura.*NOPASSWD.*ALL" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \
    "Sudo config grants laura full access" \
    "Laura doesn't have full sudo privileges"

# Test that sudo actually works for laura
check 'su - laura -c "sudo -n whoami" 2>/dev/null | grep -q root' \
    "Laura can execute sudo commands" \
    "Laura cannot use sudo - check NOPASSWD setting"
