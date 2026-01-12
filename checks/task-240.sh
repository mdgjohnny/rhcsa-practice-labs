#!/usr/bin/env bash
# Task: Create a Containerfile that builds from ubi8, sets environment variable APP_ENV=production, and build as myapp:prod.
# Title: Containerfile with Environment Variable
# Category: containers
# Target: node1

check '[[ -f /root/myapp/Containerfile ]] || [[ -f /root/myapp/Dockerfile ]]' \
    "Containerfile exists" \
    "Containerfile not found"

check 'grep -qE "ENV.*APP_ENV.*production" /root/myapp/Containerfile 2>/dev/null || grep -qE "ENV.*APP_ENV.*production" /root/myapp/Dockerfile 2>/dev/null' \
    "Containerfile sets APP_ENV" \
    "ENV APP_ENV not found"

check 'podman images | grep -qE "myapp.*prod"' \
    "myapp:prod image built" \
    "myapp:prod image not found"
