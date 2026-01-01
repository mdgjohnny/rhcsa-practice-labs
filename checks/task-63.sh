#!/usr/bin/env bash
# Task: Install "Development Tools" group, capture info to /var/tmp/systemtools.out
# Category: deploy-maintain

check 'dnf group list installed 2>/dev/null | grep -qi "development tools"' \
    "Development Tools group is installed" \
    "Development Tools group is not installed"

check '[[ -f /var/tmp/systemtools.out ]]' \
    "File /var/tmp/systemtools.out exists" \
    "File /var/tmp/systemtools.out does not exist"
