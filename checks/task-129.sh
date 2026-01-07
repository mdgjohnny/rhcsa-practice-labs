#!/usr/bin/env bash
# Task: Create 500MiB ext4 partition on second disk, mount on /mydata with label mydata
# Title: Create ext4 Partition with Label
# Category: file-systems
# Target: node1


check '[[ -d /mydata ]]' \
    "Directory /mydata exists" \
    "Directory /mydata does not exist"
