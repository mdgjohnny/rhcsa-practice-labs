#!/usr/bin/env bash
# Task: Create Stratis pool and volume 'stratisvol' on 10GiB disk, mount on /stratis
# Category: local-storage
# Target: node1


check '[[ -d /stratis ]]' \
    "Directory /stratis exists" \
    "Directory /stratis does not exist"
