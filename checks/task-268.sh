#!/usr/bin/env bash
# Task: Set the system timezone to UTC.
# Title: Set Timezone to UTC
# Category: deploy-maintain
# Target: node1

check 'timedatectl | grep -qE "Time zone:.*UTC|Timezone:.*UTC"' \
    "Timezone is set to UTC" \
    "Timezone is not UTC"
