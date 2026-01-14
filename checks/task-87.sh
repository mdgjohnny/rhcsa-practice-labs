#!/usr/bin/env bash
# Task: Configure autofs for automounting home directories from rhcsa2. When a user accesses /nethome/<username>, it should mount rhcsa2:/home/<username> automatically using a wildcard map.
# Title: Configure Autofs for Network Home Directories
# Category: networking
# Target: node1

check 'rpm -q autofs &>/dev/null' \
    "autofs package installed" \
    "autofs not installed"

check 'systemctl is-active autofs &>/dev/null' \
    "autofs service is running" \
    "autofs service is not running"

check 'grep -rqE "/nethome" /etc/auto.master /etc/auto.master.d/ 2>/dev/null' \
    "/nethome configured in auto.master" \
    "/nethome not in auto.master"

check 'grep -rqE "^\s*\*\s+" /etc/auto.* 2>/dev/null' \
    "Wildcard entry found in autofs map" \
    "No wildcard (*) entry found"
