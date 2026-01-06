#!/usr/bin/env bash
# Task: Reboot your server. Assume that you don't know the root password, and use the appropriate mode to enter a root shell that doesn't require a password. Set the root password to mypassword
# Category: operate-systems
# Target: node1

# Note: This task tests password recovery - we verify root can login
# The password should have been changed to mypassword
check 'echo "mypassword" | su - root -c "echo success" 2>/dev/null | grep -q success || getent shadow root | cut -d: -f2 | grep -q "^\$"' \
    "Root password appears to be set (verification limited)" \
    "Cannot verify root password change"

# Alternative: check that root account is not locked
check '! passwd -S root 2>/dev/null | grep -q "LK\|L "' \
    "Root account is not locked" \
    "Root account is locked"
