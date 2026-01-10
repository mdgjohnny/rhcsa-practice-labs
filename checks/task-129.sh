#!/usr/bin/env bash
# Task: Using /dev/loop1, create 500MiB ext4 partition with label "mydata". Mount persistently on /mydata.
# Title: Create Labeled Partition
# Category: file-systems
# Target: node1


check '[[ -d /mydata ]]' \
    "Directory /mydata exists" \
    "Directory /mydata does not exist"
