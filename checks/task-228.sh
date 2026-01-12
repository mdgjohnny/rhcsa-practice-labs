#!/usr/bin/env bash
# Task: Pull the nginx:alpine image from Docker Hub.
# Title: Pull Alpine-based Image
# Category: containers
# Target: node1

check 'podman images | grep -qE "nginx.*alpine"' \
    "nginx:alpine image is pulled" \
    "nginx:alpine image not found"
