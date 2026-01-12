#!/usr/bin/env bash
# Task: Configure autofs to automatically mount any subdirectory from rhcsa2:/home to /nethome using wildcard mapping.
# Title: Configure Autofs Indirect Wildcard Mount
# Category: file-systems
# Target: node1

check 'systemctl is-active autofs &>/dev/null' \
    "autofs service is running" \
    "autofs service not running"

check 'grep -rq "/nethome" /etc/auto.master /etc/auto.master.d/ 2>/dev/null' \
    "nethome configured in auto.master" \
    "nethome not found in auto.master"

check 'grep -rq "\*" /etc/auto.* 2>/dev/null' \
    "Wildcard mapping configured" \
    "No wildcard mapping found"
