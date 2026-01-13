#!/usr/bin/env bash
# Task: Set the system timezone to Europe/London.
# Title: Set Timezone Europe/London
# Category: deploy-maintain
# Target: node1

check 'timedatectl | grep -q "Europe/London"' \
    "Timezone is set to Europe/London" \
    "Timezone is not Europe/London"
