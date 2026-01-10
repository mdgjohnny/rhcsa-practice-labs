#!/usr/bin/env bash
# Task: Install vsftpd package and configure it to start automatically at boot. Verify: systemctl is-enabled vsftpd
# Title: Install and Enable vsftpd
# Category: operate-systems
# Target: node1


check 'systemctl is-active vsftpd &>/dev/null' \
    "Service vsftpd is running" \
    "Service vsftpd is not running"
check 'systemctl is-enabled vsftpd &>/dev/null' \
    "Service vsftpd is enabled" \
    "Service vsftpd is not enabled"
