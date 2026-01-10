#!/usr/bin/env bash
# Task: Configure boot process to show boot messages (not silent mode).
# Title: Enable Boot Messages
# Category: deploy-maintain

check '! grep -q "rhgb\|quiet" /etc/default/grub 2>/dev/null || grep -q "^#.*rhgb\|^#.*quiet" /etc/default/grub 2>/dev/null' \
    "Boot messages are not silenced" \
    "Boot messages are silenced (rhgb/quiet present)"
