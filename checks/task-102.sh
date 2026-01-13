#!/usr/bin/env bash
# Task: Create a containerized HTTP server. Mount /httproot from host to /var/www/html in the container.
# Title: Create HTTP Container
# Category: containers
# Target: node1


check '[[ -d /httproot ]]' \
    "Directory /httproot exists on host" \
    "Directory /httproot does not exist - create it first"

check 'podman ps --format "{{.Mounts}}" 2>/dev/null | grep -q "/httproot" || podman inspect --format "{{range .Mounts}}{{.Source}}{{end}}" $(podman ps -q 2>/dev/null) 2>/dev/null | grep -q "/httproot"' \
    "Container has /httproot mounted" \
    "No container with /httproot bind mount found"

check 'podman ps 2>/dev/null | grep -q httpd || podman ps 2>/dev/null | grep -q http' \
    "HTTP container is running" \
    "No HTTP container is running"
