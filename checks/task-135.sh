#!/usr/bin/env bash
# Task: Add a 10-GiB disk to your virtual machine. On this disk, create a Stratis pool and volume. Use the name stratisvol for the volume, and mount it persistently on the directory /stratis
# Category: local-storage
# Target: node1


check \'run_ssh "$NODE1_IP" "test -d /stratis"\' \
    "Directory /stratis exists" \
    "Directory /stratis does not exist"
