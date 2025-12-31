#!/usr/bin/env bash
# Task: Set default boot target to multi-user on both VMs

DEFAULT_TARGET=$(systemctl get-default)

check '[[ "$DEFAULT_TARGET" == "multi-user.target" ]]' \
    "Default target is multi-user.target" \
    "Default target is not multi-user.target (got $DEFAULT_TARGET)"
