#!/usr/bin/env bash
# Task: Use skopeo to copy the nginx:alpine image from Docker Hub to a local directory /root/nginx-image/.
# Title: Copy Image with Skopeo
# Category: containers
# Target: node1

check '[[ -d /root/nginx-image ]]' \
    "Directory /root/nginx-image exists" \
    "Directory not found"

check '[[ -f /root/nginx-image/manifest.json ]] || ls /root/nginx-image/*.tar 2>/dev/null' \
    "Image files present in directory" \
    "No image files found"
