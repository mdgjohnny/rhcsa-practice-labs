#!/usr/bin/env bash
# Task: Create 1GB vfat partition on /dev/sdb, mount persistently on /mydata with label mylabel
# Category: file-systems
# Target: node1


check '[[ -d /mydata ]]' \
    "Directory /mydata exists" \
    "Directory /mydata does not exist"
