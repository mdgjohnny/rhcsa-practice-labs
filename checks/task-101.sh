#!/usr/bin/env bash
# Task: Install and enable vsftpd service to start at boot
# Category: operate-systems
# Target: node1


check 'systemctl is-active vsftpd &>/dev/null' \
    "Service vsftpd is running" \
    "Service vsftpd is not running"
check 'systemctl is-enabled vsftpd &>/dev/null' \
    "Service vsftpd is enabled" \
    "Service vsftpd is not enabled"
