#!/usr/bin/env bash
# Task: As user student, create /home/student/mysql-data directory. Run a MariaDB container with /home/student/mysql-data:/var/lib/mysql bind mount on port 3308. Create and enable a systemd user service named "mariadb". Ensure the service starts at boot.
# Title: Rootless Container as Student User
# Category: containers
# Target: node1


check 'id student &>/dev/null' \
    "User student exists" \
    "User student does not exist"

check 'su - student -c "[[ -d ~/mysql-data ]]"' \
    "Directory /home/student/mysql-data exists" \
    "Directory /home/student/mysql-data does not exist"

check 'su - student -c "systemctl --user is-active mariadb" &>/dev/null' \
    "User service mariadb is running" \
    "User service mariadb is not running"

check 'su - student -c "systemctl --user is-enabled mariadb" &>/dev/null' \
    "User service mariadb is enabled" \
    "User service mariadb is not enabled"

check 'loginctl show-user student -p Linger 2>/dev/null | grep -q "yes"' \
    "Lingering enabled for student" \
    "Lingering not enabled for student"

check 'su - student -c "podman ps 2>/dev/null" | grep -qi mariadb' \
    "MariaDB container is running as student" \
    "No MariaDB container running as student"

check 'ss -tlnp | grep -q ":3308"' \
    "Port 3308 is listening" \
    "Port 3308 is not listening"
