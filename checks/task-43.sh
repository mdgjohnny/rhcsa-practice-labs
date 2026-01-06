#!/usr/bin/env bash
# Task: Search man pages for "password", output to /var/tmp/man.out
# Category: essential-tools

check \'run_ssh "$NODE1_IP" "test -f /var/tmp/man.out"\' \
    "File /var/tmp/man.out exists" \
    "File /var/tmp/man.out does not exist"

check '[[ -s /var/tmp/man.out ]]' \
    "/var/tmp/man.out is not empty" \
    "/var/tmp/man.out is empty"
