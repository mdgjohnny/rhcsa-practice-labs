#!/usr/bin/env bash
# Task: Install the vsftpd service and ensure that it is started automatically at reboot
# Category: operate-systems
# Target: node1


check \'run_ssh "$NODE1_IP" "systemctl is-active vsftpd &>/dev/null"\' \
    "Service vsftpd is running" \
    "Service vsftpd is not running"
check \'run_ssh "$NODE1_IP" "systemctl is-enabled vsftpd &>/dev/null"\' \
    "Service vsftpd is enabled" \
    "Service vsftpd is not enabled"
