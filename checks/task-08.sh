#!/usr/bin/env bash
# Task: Configure system to use BaseOS and AppStream repositories.
# Title: Configure System Repositories
# Category: file-systems
# Target: node1

# Check if BaseOS repo is configured and enabled
check 'dnf repolist 2>/dev/null | grep -qiE "baseos|BaseOS"' \
    "BaseOS repository is available" \
    "BaseOS repository is not configured"

# Check if AppStream repo is configured and enabled
check 'dnf repolist 2>/dev/null | grep -qiE "appstream|AppStream"' \
    "AppStream repository is available" \
    "AppStream repository is not configured"
