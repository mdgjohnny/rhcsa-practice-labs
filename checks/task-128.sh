#!/usr/bin/env bash
# Task: As user student, create /home/student/mysql-student directory. Run a MariaDB container named "mariadb-student" with /home/student/mysql-student:/var/lib/mysql bind mount on port 3308. Create and enable a systemd user service named "mariadb-student". Ensure the service starts at boot.
# Title: Rootless Container as Student User
# Category: containers
# Target: node1


check 'id student &>/dev/null' \
    "User student exists" \
    "User student does not exist"

check '[[ -d /home/student/mysql-student ]]' \
    "Directory /home/student/mysql-student exists" \
    "Directory /home/student/mysql-student does not exist"

check 'sudo runuser -l student -c "export XDG_RUNTIME_DIR=/run/user/\$(id -u); systemctl --user is-active mariadb-student" &>/dev/null' \
    "User service mariadb-student is running" \
    "User service mariadb-student is not running"

check 'sudo runuser -l student -c "export XDG_RUNTIME_DIR=/run/user/\$(id -u); systemctl --user is-enabled mariadb-student" &>/dev/null' \
    "User service mariadb-student is enabled" \
    "User service mariadb-student is not enabled"

check 'loginctl show-user student -p Linger 2>/dev/null | grep -q "yes"' \
    "Lingering enabled for student" \
    "Lingering not enabled for student"

check 'sudo runuser -l student -c "podman ps" 2>/dev/null | grep -q mariadb-student' \
    "Container mariadb-student is running" \
    "Container mariadb-student is not running"

check 'ss -tlnp | grep -q ":3308"' \
    "Port 3308 is listening" \
    "Port 3308 is not listening"
