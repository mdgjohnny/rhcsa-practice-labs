#!/usr/bin/env bash
# Task: Configure the boot process to show verbose boot messages instead of silent mode. Remove any options that hide boot output.
# Title: Enable Boot Messages
# Category: deploy-maintain
# Target: node1

# Check /etc/default/grub doesn't have rhgb or quiet (non-commented)
check '! grep -E "^GRUB_CMDLINE_LINUX=" /etc/default/grub | grep -qE "rhgb|quiet"' \
    "GRUB_CMDLINE_LINUX doesn't contain rhgb/quiet" \
    "GRUB_CMDLINE_LINUX still has rhgb or quiet"

# Check that grub.cfg was regenerated (or grubby was used)
check '! grep -q "rhgb" /boot/grub2/grub.cfg 2>/dev/null || grubby --info=DEFAULT 2>/dev/null | grep -qv "rhgb"' \
    "Boot config updated (grub.cfg or grubby)" \
    "Boot config may not be updated - run grub2-mkconfig or grubby"
