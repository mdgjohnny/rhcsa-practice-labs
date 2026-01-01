#!/usr/bin/env bash
# Task: Set hostname on node1
# Category: networking

LOCAL_HOSTNAME=$(hostname -s)

check '[[ "$LOCAL_HOSTNAME" == "$NODE1" ]]' \
    "Hostname set to $NODE1" \
    "Hostname not set to $NODE1 (got $LOCAL_HOSTNAME)"
