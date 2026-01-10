#!/usr/bin/env bash
# Task: Using /dev/loop0, create a 1GB vfat partition. Label it "mylabel" and mount persistently on /mydata.
# Title: Create VFAT Partition
# Category: file-systems
# Target: node1


check '[[ -d /mydata ]]' \
    "Directory /mydata exists" \
    "Directory /mydata does not exist"
