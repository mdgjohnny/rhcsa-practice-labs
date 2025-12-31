#!/usr/bin/env bash
# Task: Boot messages should be present (not silenced)

check '! grep -q "rhgb\|quiet" /etc/default/grub 2>/dev/null || grep -q "^#.*rhgb\|^#.*quiet" /etc/default/grub 2>/dev/null' \
    "Boot messages are not silenced" \
    "Boot messages are silenced (rhgb/quiet present)"
