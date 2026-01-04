#!/usr/bin/env bash
# Task: Add a custom message “This is RHCSA sample exam on $ by $LOGNAME” to the /var/log/messages file as the root user Use regular expression to confirm the message entry to the log file
# Category: users-groups
# Target: node1


check 'id use &>/dev/null' \
    "User use exists" \
    "User use does not exist"
