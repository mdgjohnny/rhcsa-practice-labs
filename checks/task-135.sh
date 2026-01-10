#!/usr/bin/env bash
# Task: Create Stratis pool on a 10GiB disk. Create volume "stratisvol" and mount persistently on /stratis.
# Title: Configure Stratis Storage
# Category: local-storage
# Target: node1


check '[[ -d /stratis ]]' \
    "Directory /stratis exists" \
    "Directory /stratis does not exist"
