#!/usr/bin/env bash
# Task: Attach RHEL 9 ISO as /rhel9.iso, mount on /repo, configure BaseOS and AppStream repos
# Category: file-systems

ISO_FILENAME="${ISO_FILENAME:-rhel9.iso}"

check '[[ -f "/${ISO_FILENAME}" ]] && file "/${ISO_FILENAME}" | grep -qi iso' \
    "ISO file /${ISO_FILENAME} was found" \
    "No ISO file /${ISO_FILENAME} found"

check 'mount | grep -q "/repo"' \
    "Something is mounted on /repo" \
    "Nothing is mounted on /repo"

check 'grep -q "file:///repo/BaseOS" /etc/yum.repos.d/* 2>/dev/null' \
    "BaseOS repository configured from /repo" \
    "BaseOS repository not configured from /repo"

check 'grep -q "file:///repo/AppStream" /etc/yum.repos.d/* 2>/dev/null' \
    "AppStream repository configured from /repo" \
    "AppStream repository not configured from /repo"
