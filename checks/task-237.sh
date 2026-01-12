#!/usr/bin/env bash
# Task: Use skopeo to list tags available for the nginx image on Docker Hub. Save to /root/nginx-tags.txt.
# Title: List Image Tags with Skopeo
# Category: containers
# Target: node1

check '[[ -f /root/nginx-tags.txt ]]' \
    "File /root/nginx-tags.txt exists" \
    "File not found"

check 'grep -qE "latest|alpine|stable" /root/nginx-tags.txt' \
    "File contains nginx tags" \
    "No tags found"
