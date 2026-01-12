#!/usr/bin/env bash
# Task: Create a script /root/svccheck.sh that takes a service name as argument and prints "running" if the service is active, "stopped" if inactive, or "unknown" if service doesn't exist.
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

check 'systemctl stop atd 2>/dev/null; /root/svccheck.sh atd 2>/dev/null | grep -qi "stopped"; systemctl start atd 2>/dev/null' \
    "Script correctly identifies stopped service" \
    "Script fails for stopped service"
