#!/usr/bin/env bash
# Task: As user santos, create MySQL container with root password "password".
# Title: MySQL Rootless Container
# Category: containers
# Target: node2
# Bind mount /home/santos/mysql to /var/lib/mysql, auto-start via systemd

check 'id santos &>/dev/null' \
    "User santos exists" \
    "User santos does not exist"

check '[[ -d /home/santos/mysql ]]' \
    "/home/santos/mysql exists" \
    "/home/santos/mysql does not exist"

check 'loginctl show-user santos 2>/dev/null | grep -q Linger=yes' \
    "Linger enabled for santos" \
    "Linger not enabled for santos"

check 'su - santos -c "podman ps -a 2>/dev/null" | grep -qi mysql' \
    "santos has MySQL container" \
    "santos does not have MySQL container"
