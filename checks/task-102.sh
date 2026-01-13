#!/usr/bin/env bash
# Task: Create a containerized HTTP server. Mount /httproot from host to /var/www/html in the container.
# Title: Create HTTP Container
# Category: containers
# Target: node1


check '[[ -d /httproot ]]' \
    "Directory /httproot exists on host" \
    "Directory /httproot does not exist - create it first"

# Check for container with /httproot mount (as root or any user)
check 'podman inspect --format "{{range .Mounts}}{{.Source}}{{end}}" $(podman ps -q 2>/dev/null | head -1) 2>/dev/null | grep -q "/httproot" || su - opc -c "podman inspect --format \"{{range .Mounts}}{{.Source}}{{end}}\" \$(podman ps -q 2>/dev/null | head -1) 2>/dev/null" | grep -q "/httproot"' \
    "Container has /httproot mounted" \
    "No container with /httproot bind mount found"

# Check for running httpd container (as root or any user)
check 'podman ps 2>/dev/null | grep -qE "httpd|http" || su - opc -c "podman ps 2>/dev/null" | grep -qE "httpd|http"' \
    "HTTP container is running" \
    "No HTTP container is running"
