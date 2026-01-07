#!/usr/bin/env bash
# Task: Configure journald for persistent storage under /var/log/journal
# Title: Configure Persistent Journal
# Category: operate-systems

check '[[ -d /var/log/journal ]]' \
    "Directory /var/log/journal exists" \
    "Directory /var/log/journal does not exist"

check 'grep -q "^Storage=persistent" /etc/systemd/journald.conf 2>/dev/null' \
    "journald configured for persistent storage" \
    "journald not configured for persistent storage"
