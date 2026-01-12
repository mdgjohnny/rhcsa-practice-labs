#!/usr/bin/env bash
# Task: Search for images containing "mariadb" in the registry and save the results to /root/mariadb-images.txt.
# Title: Search Container Registry
# Category: containers
# Target: node1

check '[[ -f /root/mariadb-images.txt ]]' \
    "File /root/mariadb-images.txt exists" \
    "File not found"

check 'grep -qi "mariadb" /root/mariadb-images.txt' \
    "File contains mariadb images" \
    "No mariadb images found"
