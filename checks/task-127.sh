#!/usr/bin/env bash
# Task: As root, create /var/mariadb directory. Run a MariaDB container as root with /var/mariadb:/var/lib/mysql bind mount. Create a system service named "mariadb" using podman generate systemd. Enable and start it.
# Title: Root Container with Systemd Service
# Category: containers
# Target: node1


check '[[ -d /var/mariadb ]]' \
    "Directory /var/mariadb exists" \
    "Directory /var/mariadb does not exist"

check 'systemctl is-active mariadb &>/dev/null' \
    "System service mariadb is running" \
    "System service mariadb is not running (use: sudo systemctl start mariadb)"

check 'systemctl is-enabled mariadb &>/dev/null' \
    "System service mariadb is enabled" \
    "System service mariadb is not enabled (use: sudo systemctl enable mariadb)"

check 'podman ps 2>/dev/null | grep -qi mariadb' \
    "MariaDB container is running (root)" \
    "No MariaDB container running as root"

check 'ss -tlnp | grep -q ":3306"' \
    "Port 3306 is listening" \
    "Port 3306 is not listening"
