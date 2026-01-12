#!/usr/bin/env bash
# Task: Pull the httpd image from docker.io/library/httpd:latest.
# Title: Pull Docker Hub Image
# Category: containers
# Target: node1

check 'podman images | grep -qE "docker.io.*httpd|httpd.*latest"' \
    "httpd image is pulled" \
    "httpd image not found"
