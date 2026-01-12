#!/usr/bin/env bash
# Task: Apply the tuned profile that optimizes the system for maximum throughput performance.
# Title: Apply Tuned Performance Profile
# Category: deploy-maintain
# Target: node1

check 'tuned-adm active | grep -qi throughput' \
    "Throughput-optimized tuned profile is active" \
    "Throughput-optimized tuned profile is not active"
