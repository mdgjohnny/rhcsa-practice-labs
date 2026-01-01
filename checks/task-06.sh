#!/usr/bin/env bash
# Task: Checks whether HTTP port 8081/TCP has been added to the SELinux policy
# Category: security
# DB persistently

check 'semanage port -l | grep 8081 &> /dev/null' \
    'HTTP port 8081/TCP has been added to the SELinux Policy' \
    'HTTP port 8081/TCP has not been added to the SELinux Policy'
