#!/usr/bin/env bash
# Task: Create a 1-GB partition on /dev/sdb. Format it with the vfat file system Mount it persistently on the directory /mydata, using the label mylabel
# Category: file-systems
# Target: node1


check \'run_ssh "$NODE1_IP" "test -d /mydata"\' \
    "Directory /mydata exists" \
    "Directory /mydata does not exist"
