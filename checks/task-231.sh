#!/usr/bin/env bash
# Task: Pull the ubi8-minimal image from registry.access.redhat.com.
# Title: Pull from Red Hat Registry
# Category: containers
# Target: node1

check 'podman images | grep -qE "ubi8-minimal|ubi8/ubi-minimal"' \
    "ubi8-minimal image is pulled" \
    "ubi8-minimal image not found"
