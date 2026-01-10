#!/usr/bin/env bash
# Task: Add port 8081/TCP to the SELinux http_port_t type. This allows HTTP services to bind to port 8081.
# Title: Add SELinux HTTP Port
# Category: security
# DB persistently

check 'semanage port -l | grep 8081 &> /dev/null' \
    'HTTP port 8081/TCP has been added to the SELinux Policy' \
    'HTTP port 8081/TCP has not been added to the SELinux Policy'
