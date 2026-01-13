#!/usr/bin/env bash
# Task: As root, create /var/mariadb-root directory. Run a MariaDB container named "mariadb-root" with /var/mariadb-root:/var/lib/mysql bind mount on port 3306. Create and enable a system service named "mariadb-root".
# Title: Root Container with Systemd Service
# Category: containers
# Target: node1


check '[[ -d /var/mariadb-root ]]' \
    "Directory /var/mariadb-root exists" \
    "Directory /var/mariadb-root does not exist"

# Accept either mariadb-root or container-mariadb-root (podman default name)
check 'systemctl is-active mariadb-root &>/dev/null || systemctl is-active container-mariadb-root &>/dev/null' \
    "System service mariadb-root is running" \
    "System service mariadb-root is not running"

check 'systemctl is-enabled mariadb-root &>/dev/null || systemctl is-enabled container-mariadb-root &>/dev/null' \
    "System service mariadb-root is enabled" \
    "System service mariadb-root is not enabled"

check 'podman ps 2>/dev/null | grep -q mariadb-root' \
    "Container mariadb-root is running" \
    "Container mariadb-root is not running"

check 'ss -tlnp | grep -q ":3306"' \
    "Port 3306 is listening" \
    "Port 3306 is not listening"
