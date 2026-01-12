#!/usr/bin/env bash
# Task: Verify the system is running a RHEL-compatible operating system with adequate resources.
# Title: Verify RHEL-Compatible System
# Category: operate-systems
# Target: node1

# Check for RHEL-compatible OS (RHEL, CentOS, Rocky, Alma, Oracle Linux)
check 'cat /etc/redhat-release 2>/dev/null | grep -qiE "Red Hat|Rocky|AlmaLinux|CentOS|Oracle"' \
    "System is running RHEL-compatible OS" \
    "System is not RHEL-compatible"

# Check for minimum RAM (1.5GB for cloud free tier)
check '[[ $(grep MemTotal /proc/meminfo | awk "{print \$2}") -ge 900000 ]]' \
    "System has adequate RAM" \
    "System has insufficient RAM"
