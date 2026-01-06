#!/usr/bin/env bash
# Task: Install a RHEL 9 virtual machine that meets the following requirements
# Category: operate-systems
# Target: node1

# Note: This is a VM setup task - verify the VM is running RHEL 9
check \'run_ssh "$NODE1_IP" "cat /etc/redhat-release 2>/dev/null | grep -qi "Red Hat.*9\|Rocky.*9\|AlmaLinux.*9\|CentOS.*9""\' \
    "System is running RHEL 9 or compatible" \
    "System is not RHEL 9 compatible"

# Check for minimum RAM (2GB = 2097152 KB)
check '[[ $(grep MemTotal /proc/meminfo | awk "{print \$2}") -ge 1800000 ]]' \
    "System has at least 2GB RAM" \
    "System has less than 2GB RAM"
