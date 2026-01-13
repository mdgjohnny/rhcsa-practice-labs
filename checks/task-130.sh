#!/usr/bin/env bash
# Task: As user opc, create /home/opc/mysql-opc directory. Run a MariaDB container named "mariadb-opc" with /home/opc/mysql-opc:/var/lib/mysql bind mount on port 3307. Create and enable a systemd user service named "mariadb-opc". Ensure the service starts at boot.
# Title: Rootless Container with User Service
# Category: containers
# Target: node1


check '[[ -d /home/opc/mysql-opc ]]' \
    "Directory /home/opc/mysql-opc exists" \
    "Directory /home/opc/mysql-opc does not exist"

# Accept either mariadb-opc or container-mariadb-opc (podman default name)
check 'su - opc -c "systemctl --user is-active mariadb-opc || systemctl --user is-active container-mariadb-opc" &>/dev/null' \
    "User service mariadb-opc is running" \
    "User service mariadb-opc is not running"

check 'su - opc -c "systemctl --user is-enabled mariadb-opc || systemctl --user is-enabled container-mariadb-opc" &>/dev/null' \
    "User service mariadb-opc is enabled" \
    "User service mariadb-opc is not enabled"

check 'loginctl show-user opc -p Linger 2>/dev/null | grep -q "yes"' \
    "Lingering enabled for opc" \
    "Lingering not enabled for opc"

check 'su - opc -c "podman ps" 2>/dev/null | grep -q mariadb-opc' \
    "Container mariadb-opc is running" \
    "Container mariadb-opc is not running"

check 'ss -tlnp | grep -q ":3307"' \
    "Port 3307 is listening" \
    "Port 3307 is not listening"
