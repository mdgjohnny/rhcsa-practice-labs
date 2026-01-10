#!/usr/bin/env bash
# Task: Configure systemd-journald for persistent storage in /var/log/journal. Logs must survive reboots.
# Title: Enable Persistent Journaling
# Category: operate-systems
# Target: node1

check '[[ -d /var/log/journal ]]' \
    "Directory /var/log/journal exists" \
    "Directory /var/log/journal does not exist"

check 'grep -q "^Storage=persistent" /etc/systemd/journald.conf 2>/dev/null' \
    "journald configured for persistent storage" \
    "journald not configured for persistent storage"
