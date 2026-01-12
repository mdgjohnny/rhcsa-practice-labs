#!/usr/bin/env bash
# Task: Inspect the ubi8 image and find its default working directory. Save to /root/ubi8-workdir.txt.
# Title: Inspect Image Working Directory
# Category: containers
# Target: node1

check '[[ -f /root/ubi8-workdir.txt ]]' \
    "File /root/ubi8-workdir.txt exists" \
    "File not found"
