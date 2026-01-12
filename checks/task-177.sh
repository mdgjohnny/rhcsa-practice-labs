#!/usr/bin/env bash
# Task: Use skopeo to inspect the docker.io/library/nginx:latest image WITHOUT pulling it. Save the output showing available tags to /root/nginx-info.txt.
# Title: Inspect Remote Image with Skopeo
# Category: containers
# Target: node1

check 'command -v skopeo &>/dev/null' \
    "skopeo is installed" \
    "skopeo not found (install with dnf install skopeo)"

check '[[ -f /root/nginx-info.txt ]]' \
    "File /root/nginx-info.txt exists" \
    "File /root/nginx-info.txt not found"

check 'grep -qiE "nginx|docker\.io|digest|layers" /root/nginx-info.txt' \
    "File contains nginx image information" \
    "File doesn't contain expected image info"
