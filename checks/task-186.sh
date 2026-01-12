#!/usr/bin/env bash
# Task: Find the SELinux context of the sshd process and save it to /root/sshd-context.txt.
# Title: List SELinux Process Context
# Category: security
# Target: node1

check '[[ -f /root/sshd-context.txt ]]' \
    "File /root/sshd-context.txt exists" \
    "File /root/sshd-context.txt not found"

check 'grep -qE "_t" /root/sshd-context.txt' \
    "File contains SELinux type" \
    "No SELinux type found"

check 'grep -qE "sshd_t|unconfined" /root/sshd-context.txt' \
    "Context is correct for sshd process" \
    "Context doesn't appear correct for sshd"
