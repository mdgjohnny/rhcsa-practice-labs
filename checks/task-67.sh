#!/usr/bin/env bash
# Task: The server needs to serve web traffic on an interface assigned to the external zone. Enable the HTTP service in this zone permanently.
# Title: Enable HTTP in External Zone
# Category: security
# Target: node1

check 'firewall-cmd --zone=external --list-services 2>/dev/null | grep -q "http"' \
    "HTTP service is enabled in external zone" \
    "HTTP service is not enabled in external zone"

check 'firewall-cmd --permanent --zone=external --list-services 2>/dev/null | grep -q "http"' \
    "Configuration is persistent" \
    "Rule will not survive reboot (use --permanent)"
