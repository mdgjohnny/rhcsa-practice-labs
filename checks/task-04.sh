#!/usr/bin/env bash
# Task: Set hostname on node2
# Category: networking

LOCAL_HOSTNAME=$(hostname -s)

check '[[ "$LOCAL_HOSTNAME" == "$NODE2" ]]' \
    "Hostname set to $NODE2" \
    "Hostname not set to $NODE2 (got $LOCAL_HOSTNAME)"
