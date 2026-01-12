#!/usr/bin/env bash
# Task: Pull the redis image and tag it as myredis:v1 locally.
# Title: Pull and Tag Container Image
# Category: containers
# Target: node1

check 'podman images | grep -qE "myredis.*v1"' \
    "myredis:v1 image exists" \
    "myredis:v1 not found (pull redis and tag it)"
