#!/usr/bin/env bash
# Task: Deploy a MySQL container named "mydb" using docker.io/library/mysql:latest. Set MYSQL_ROOT_PASSWORD=redhat123. The container must be running.
# Title: Deploy MySQL Container
# Category: containers
# Target: node1

# Check for MySQL container running (root or opc user)
check 'podman ps 2>/dev/null | grep -q mysql || su - opc -c "podman ps 2>/dev/null" | grep -q mysql' \
    "MySQL container is running" \
    "No MySQL container running"

# Check container is named 'mydb'
check 'podman ps --format "{{.Names}}" 2>/dev/null | grep -q mydb || su - opc -c "podman ps --format \"{{.Names}}\" 2>/dev/null" | grep -q mydb' \
    "Container is named 'mydb'" \
    "No container named 'mydb' found"

# Check MYSQL_ROOT_PASSWORD is set (inspect the container)
check 'podman inspect mydb --format "{{.Config.Env}}" 2>/dev/null | grep -q MYSQL_ROOT_PASSWORD || su - opc -c "podman inspect mydb --format \"{{.Config.Env}}\" 2>/dev/null" | grep -q MYSQL_ROOT_PASSWORD' \
    "MYSQL_ROOT_PASSWORD environment variable is set" \
    "MYSQL_ROOT_PASSWORD not configured"
