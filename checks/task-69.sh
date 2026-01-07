#!/usr/bin/env bash
# Task: Launch container as user20 using ubi9 with SHELL and HOSTNAME vars
# Title: Container with Env Variables
# Category: containers
# Auto-start via systemd without login

check 'su - user20 -c "podman ps -a 2>/dev/null | grep -qi ubi9"' \
    "user20 has ubi9 container" \
    "user20 does not have ubi9 container"

check 'loginctl show-user user20 2>/dev/null | grep -q "Linger=yes"' \
    "Linger enabled for user20" \
    "Linger not enabled for user20"
