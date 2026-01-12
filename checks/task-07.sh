#!/usr/bin/env bash
# Task: Set the system timezone to America/New_York.
# Title: Set System Timezone
# Category: deploy-maintain
# Target: node1

check 'timedatectl | grep -q "America/New_York"' \
    "Timezone is set to America/New_York" \
    "Timezone is not America/New_York"
