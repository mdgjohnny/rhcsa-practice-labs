#!/usr/bin/env bash
# Task: Create a Containerfile with a WORKDIR of /app, and ENTRYPOINT that runs a script. Build as myentrypoint:v1.
# Title: Containerfile with WORKDIR and ENTRYPOINT
# Category: containers
# Target: node1

check 'grep -qE "WORKDIR.*/app" /root/myentry/Containerfile 2>/dev/null || grep -qE "WORKDIR.*/app" /root/myentry/Dockerfile 2>/dev/null' \
    "Containerfile has WORKDIR /app" \
    "WORKDIR not found"

check 'grep -qE "ENTRYPOINT" /root/myentry/Containerfile 2>/dev/null || grep -qE "ENTRYPOINT" /root/myentry/Dockerfile 2>/dev/null' \
    "Containerfile has ENTRYPOINT" \
    "ENTRYPOINT not found"

check 'podman images | grep -qE "myentrypoint.*v1"' \
    "myentrypoint:v1 image built" \
    "myentrypoint:v1 not found"
