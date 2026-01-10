#!/usr/bin/env bash
# Task: Create 500MiB ext4 partition on second disk with label "mydata". Mount persistently on /mydata.
# Title: Create Labeled Partition
# Category: file-systems
# Target: node1


check '[[ -d /mydata ]]' \
    "Directory /mydata exists" \
    "Directory /mydata does not exist"
