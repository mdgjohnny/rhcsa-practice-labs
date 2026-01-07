#!/usr/bin/env bash
# Task: Apply tuned profile for throughput optimization
# Title: Tuned Profile (throughput)
# Category: operate-systems
# Target: node1

# Check if tuned is running
check 'systemctl is-active tuned &>/dev/null' \
    "tuned service is running" \
    "tuned service is not running"

# Check if throughput-performance profile is active
check 'tuned-adm active 2>/dev/null | grep -qi "throughput"' \
    "Throughput-optimized tuned profile is active" \
    "Throughput profile is not active"
