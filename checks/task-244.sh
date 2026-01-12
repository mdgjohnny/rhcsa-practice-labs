#!/usr/bin/env bash
# Task: Create a podman volume named "dbdata" and run a MariaDB container using it for /var/lib/mysql.
# Title: Container with Named Volume
# Category: containers
# Target: node1

check 'podman volume ls | grep -q "dbdata"' \
    "Volume dbdata exists" \
    "Volume dbdata not found"

check 'podman ps -a | grep -iE "mariadb|mysql"' \
    "Database container exists" \
    "No database container found"
