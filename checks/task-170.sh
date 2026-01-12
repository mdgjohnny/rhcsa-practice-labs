#!/usr/bin/env bash
# Task: Configure system-wide default umask to 077 for all users. New files should be readable only by owner.
# Title: Configure System-wide umask
# Category: security
# Target: node1

check 'grep -rq "umask.*077" /etc/profile /etc/profile.d/*.sh /etc/bashrc 2>/dev/null' \
    "System-wide umask 077 is configured" \
    "umask 077 not found in /etc/profile, /etc/profile.d/, or /etc/bashrc"

check 'source /etc/profile 2>/dev/null; [[ $(umask) == "0077" ]]' \
    "umask 077 is active after sourcing /etc/profile" \
    "umask is not 077 after sourcing profile"
