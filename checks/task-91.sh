#!/usr/bin/env bash
# Task: Mount installation ISO on /repo, configure as only repository
# Title: Configure ISO Repository
# Category: deploy-maintain
# Target: node1


check '[[ -d /repo ]]' \
    "Directory /repo exists" \
    "Directory /repo does not exist"
