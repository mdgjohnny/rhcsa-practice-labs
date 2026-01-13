#!/usr/bin/env bash
# Task: Find which SELinux context type is used for files in /etc and save ONLY the type (e.g., etc_t) to /root/selinux-context.txt. Then create /root/testdir and apply that same context type to it persistently.
# Title: SELinux Context Discovery and Application
# Category: security
# Target: node1


check '[[ -f /root/selinux-context.txt ]]' \
    "File /root/selinux-context.txt exists" \
    "File /root/selinux-context.txt not found"

check 'grep -qx "etc_t" /root/selinux-context.txt' \
    "File contains correct context type" \
    "File does not contain the expected context type"

check '[[ -d /root/testdir ]]' \
    "Directory /root/testdir exists" \
    "Directory /root/testdir not found"

check 'ls -Zd /root/testdir 2>/dev/null | grep -q "etc_t"' \
    "/root/testdir has correct SELinux context" \
    "/root/testdir does not have correct context"

check 'semanage fcontext -l | grep -q "/root/testdir"' \
    "Context is set persistently" \
    "Context is not persistent"
