#!/usr/bin/env bash
# Task: Run MariaDB container on port 3206 (not default 3306). Set MYSQL_ROOT_PASSWORD=password and create database "mydb". Create /opt/mariadb directory and configure as bind mount for data persistence.
# Title: MariaDB Container (port 3206)
# Category: containers
# Target: node1

# Check if container is running
check 'podman ps 2>/dev/null | grep -qi mariadb || docker ps 2>/dev/null | grep -qi mariadb' \
    "MariaDB container is running" \
    "MariaDB container is not running"

# Check if port 3206 is exposed
check 'podman ps 2>/dev/null | grep -q "3206" || docker ps 2>/dev/null | grep -q "3206" || ss -tlnp | grep -q ":3206"' \
    "Port 3206 is exposed" \
    "Port 3206 is not exposed"

# Check if bind mount directory exists
check '[[ -d /opt/mariadb ]]' \
    "Directory /opt/mariadb exists" \
    "Directory /opt/mariadb does not exist"

# Check if bind mount is configured
check 'podman inspect $(podman ps -q --filter ancestor=mariadb 2>/dev/null) 2>/dev/null | grep -q "/opt/mariadb" || docker inspect $(docker ps -q --filter ancestor=mariadb 2>/dev/null) 2>/dev/null | grep -q "/opt/mariadb"' \
    "Bind mount /opt/mariadb is configured" \
    "Bind mount /opt/mariadb not found in container config"
