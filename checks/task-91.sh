#!/usr/bin/env bash
# Task: Configure your system to automatically mount the ISO of the installation disk on the directory /repo. Configure your system to remove this loop-mounted ISO as the only repository that is used for installation Do not register your system with subscription-manager, and remove all references to external repositories that may already exist
# Category: deploy-maintain
# Target: node1


check \'run_ssh "$NODE1_IP" "test -d /repo"\' \
    "Directory /repo exists" \
    "Directory /repo does not exist"
