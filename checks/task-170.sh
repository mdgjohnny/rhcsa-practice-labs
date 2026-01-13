#!/usr/bin/env bash
# Task: Configure system-wide default umask to 077 for all users. New files should be readable only by owner.
# Title: Configure System-wide umask
# Category: security
# Target: node2

# Check umask in profile files OR login.defs
check 'grep -rqE "umask.*077|UMASK.*077" /etc/profile /etc/profile.d/*.sh /etc/bashrc /etc/login.defs 2>/dev/null' \
    "System-wide umask 077 is configured" \
    "umask 077 not configured system-wide"

# Verify umask is effective (test with new shell)
check 'bash -l -c "umask" 2>/dev/null | grep -q "0077"' \
    "umask 077 is active in new login shell" \
    "umask is not 077 in new login shell"
