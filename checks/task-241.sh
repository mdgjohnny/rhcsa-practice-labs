#!/usr/bin/env bash
# Task: Create a Containerfile that installs nginx, copies a local index.html to /usr/share/nginx/html/, and build as mynginx:v1.
# Title: Containerfile with COPY Instruction
# Category: containers
# Target: node1

check 'grep -qiE "COPY.*index.html" /root/mynginx/Containerfile 2>/dev/null || grep -qiE "COPY.*index.html" /root/mynginx/Dockerfile 2>/dev/null' \
    "Containerfile uses COPY" \
    "COPY instruction not found"

check 'podman images | grep -qE "mynginx.*v1"' \
    "mynginx:v1 image built" \
    "mynginx:v1 image not found"
