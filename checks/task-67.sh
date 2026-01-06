#!/usr/bin/env bash
# Task: Add http service to external firewalld zone persistently
# Category: security

check \'run_ssh "$NODE1_IP" "firewall-cmd --zone=external --list-services | grep -q "http""\' \
    "http service is in external zone" \
    "http service is not in external zone"

check \'run_ssh "$NODE1_IP" "firewall-cmd --permanent --zone=external --list-services | grep -q "http""\' \
    "http service is persistent in external zone" \
    "http service is not persistent"
