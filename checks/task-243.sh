#!/usr/bin/env bash
# Task: Create a multi-stage Containerfile or a Containerfile that uses ARG for build-time variables. Build as myarg:v1.
# Title: Containerfile with Build Arguments
# Category: containers
# Target: node1

check 'grep -qE "ARG " /root/myarg/Containerfile 2>/dev/null || grep -qE "ARG " /root/myarg/Dockerfile 2>/dev/null' \
    "Containerfile uses ARG" \
    "ARG instruction not found"

check 'podman images | grep -qE "myarg.*v1"' \
    "myarg:v1 image built" \
    "myarg:v1 not found"
