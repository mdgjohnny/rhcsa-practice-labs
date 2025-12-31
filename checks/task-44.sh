#!/usr/bin/env bash
# Task: On rhcsa2 - Create /dir1/dir2/dir3/dir4 with SELinux contexts of /etc

check 'ssh $SSH_OPTS "$NODE2_IP" "[[ -d /dir1/dir2/dir3/dir4 ]]" 2>/dev/null' \
    "Directory hierarchy exists on node2" \
    "Directory hierarchy does not exist on node2"

check 'ssh $SSH_OPTS "$NODE2_IP" "ls -Zd /dir1 2>/dev/null | grep -q etc_t"' \
    "/dir1 has etc_t SELinux context" \
    "/dir1 does not have etc_t SELinux context"
