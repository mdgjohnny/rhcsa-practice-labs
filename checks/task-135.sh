#!/usr/bin/env bash
# Task: Using /dev/loop0, create Stratis pool. Create volume "stratisvol" and mount persistently on /stratis.
# Title: Configure Stratis Storage
# Category: local-storage
# Target: node1


check '[[ -d /stratis ]]' \
    "Directory /stratis exists" \
    "Directory /stratis does not exist"
