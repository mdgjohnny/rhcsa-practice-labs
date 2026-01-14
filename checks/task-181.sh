#!/usr/bin/env bash
# Task: Create a script /root/svccheck.sh that takes a service name as argument and prints "running" if the service is active, "stopped" if inactive, or "unknown" if the service doesn't exist.
# Title: Shell Script - Service Status Checker
# Category: shell-scripts
# Target: node1

check '[[ -x /root/svccheck.sh ]]' \
    "Script /root/svccheck.sh exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "(if |case |\[\[|\[)" /root/svccheck.sh' \
    "Script uses conditional logic" \
    "Script missing conditional construct"

check 'grep -qE "systemctl|service" /root/svccheck.sh' \
    "Script checks service status" \
    "Script doesn't use systemctl/service"

check '/root/svccheck.sh sshd 2>/dev/null | grep -qi "running"' \
    "Script correctly identifies running service (sshd)" \
    "Script fails for running service"

check '/root/svccheck.sh nonexistentservice12345 2>/dev/null | grep -qi "unknown"' \
    "Script correctly identifies unknown service" \
    "Script fails for non-existent service"
