#!/usr/bin/env bash
# Task: As user opc (rootless), create ~/dbdata directory. Run a MariaDB container with ~/dbdata:/var/lib/mysql bind mount on port 3307. Create a user service named "mariadb" using podman generate systemd. Enable lingering and start the service.
# Title: Rootless Container with User Service
# Category: containers
# Target: node1


# Check directory exists in opc home
check 'su - opc -c "[[ -d ~/dbdata ]]"' \
    "Directory ~/dbdata exists for opc" \
    "Directory ~/dbdata does not exist (create as opc user)"

# Check user service is running
check 'su - opc -c "systemctl --user is-active mariadb" &>/dev/null' \
    "User service mariadb is running" \
    "User service mariadb is not running (use: systemctl --user start mariadb)"

# Check user service is enabled
check 'su - opc -c "systemctl --user is-enabled mariadb" &>/dev/null' \
    "User service mariadb is enabled" \
    "User service mariadb is not enabled (use: systemctl --user enable mariadb)"

# Check lingering is enabled (required for user services to start at boot)
check 'loginctl show-user opc -p Linger 2>/dev/null | grep -q "yes"' \
    "Lingering enabled for opc (services start at boot)" \
    "Lingering not enabled (use: sudo loginctl enable-linger opc)"

# Check container is running as opc
check 'su - opc -c "podman ps 2>/dev/null" | grep -qi mariadb' \
    "MariaDB container is running (rootless)" \
    "No MariaDB container running as opc"

check 'ss -tlnp | grep -q ":3307"' \
    "Port 3307 is listening" \
    "Port 3307 is not listening"
