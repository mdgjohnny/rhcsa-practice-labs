#!/usr/bin/env bash
# Task: Add the http service to the external firewalld zone persistently.
# Title: Add Firewall Service
# Category: security
# Target: node1

check 'firewall-cmd --zone=external --list-services | grep -q "http"' \
    "http service is in external zone" \
    "http service is not in external zone"

check 'firewall-cmd --permanent --zone=external --list-services | grep -q "http"' \
    "http service is persistent in external zone" \
    "http service is not persistent"
