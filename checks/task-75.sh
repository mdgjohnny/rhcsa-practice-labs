#!/usr/bin/env bash
# Task: As user edwin, create MariaDB container on port 3306.
# Title: MariaDB Container
# Category: containers
# Target: node2
# /var/mariadb-container for persistent storage

check 'id edwin &>/dev/null' \
    "User edwin exists" \
    "User edwin does not exist"

check '[[ -d /var/mariadb-container ]]' \
    "/var/mariadb-container exists" \
    "/var/mariadb-container does not exist"

check 'loginctl show-user edwin 2>/dev/null | grep -q Linger=yes' \
    "Linger enabled for edwin" \
    "Linger not enabled for edwin"

check 'su - edwin -c "podman ps -a 2>/dev/null" | grep -qi mariadb' \
    "edwin has mariadb container" \
    "edwin does not have mariadb container"
