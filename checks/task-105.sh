#!/usr/bin/env bash
# Task: Create users linda and anna and set their home directories to /home/users/ linda and /home/users/anna. Make sure that while these users access their home directory, autofs is used to mount the NFS shares /users/linda and /users/anna from the same server Create user student with password password, and user root with password password
# Category: users-groups
# Target: node1


check 'id linda &>/dev/null' \
    "User linda exists" \
    "User linda does not exist"
check 'id access &>/dev/null' \
    "User access exists" \
    "User access does not exist"
check 'id student &>/dev/null' \
    "User student exists" \
    "User student does not exist"
check 'id root &>/dev/null' \
    "User root exists" \
    "User root does not exist"
check 'id root &>/dev/null' \
    "User root exists" \
    "User root does not exist"
check 'systemctl is-active autofs &>/dev/null' \
    "Service autofs is running" \
    "Service autofs is not running"
