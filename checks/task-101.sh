#!/usr/bin/env bash
# Task: Install the vsftpd package and configure it to start automatically at boot.
# Title: Install and Enable vsftpd
# Category: operate-systems
# Target: node1

check 'rpm -q vsftpd &>/dev/null' \
    "Package vsftpd is installed" \
    "Package vsftpd is not installed"

check 'systemctl is-enabled vsftpd 2>/dev/null | grep -q enabled' \
    "Service vsftpd is enabled at boot" \
    "Service vsftpd is not enabled at boot"
