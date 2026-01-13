#!/usr/bin/env bash
# Task: Create /var/mariadb directory. Run MariaDB container on port 3306 with /var/mariadb:/var/lib/mysql bind mount for persistent data. Create and enable a systemd service named "mariadb" that starts the container at boot.
# Title: MariaDB Container Service
# Category: containers
# Target: node1


check '[[ -d /var/mariadb ]]' \
    "Directory /var/mariadb exists" \
    "Directory /var/mariadb does not exist"

check 'systemctl is-active mariadb &>/dev/null' \
    "Service mariadb is running" \
    "Service mariadb is not running"

check 'systemctl is-enabled mariadb &>/dev/null' \
    "Service mariadb is enabled" \
    "Service mariadb is not enabled"

# Check for MariaDB container running (root or rootless)
check 'podman ps 2>/dev/null | grep -qi mariadb || su - opc -c "podman ps 2>/dev/null" | grep -qi mariadb' \
    "MariaDB container is running" \
    "No MariaDB container is running"

check 'ss -tlnp | grep -q ":3306"' \
    "Port 3306 is listening" \
    "Port 3306 is not listening"
