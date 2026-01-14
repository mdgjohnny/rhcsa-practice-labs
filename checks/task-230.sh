#!/usr/bin/env bash
# Task: Search container registries for images containing "mariadb" and save the results to /root/mariadb-images.txt.
# Title: Search Container Registry
# Category: containers
# Target: node1

check '[[ -f /root/mariadb-images.txt ]]' \
    "File /root/mariadb-images.txt exists" \
    "File not found"

check '[[ -s /root/mariadb-images.txt ]]' \
    "File has content" \
    "File is empty"

check 'grep -qi "mariadb" /root/mariadb-images.txt' \
    "File contains mariadb images" \
    "No mariadb references found in file"

check 'grep -qE "docker\.io|quay\.io|registry|INDEX" /root/mariadb-images.txt' \
    "File appears to be registry search output" \
    "File doesn't look like registry search output"
