#!/usr/bin/env bash
# Task: Create a container using docker.io/library/mysql:latest image with appropriate configuration.
# Title: Deploy MySQL Container
# Category: containers
# Target: node1


check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \
    "Container is running" \
    "No container is running"
