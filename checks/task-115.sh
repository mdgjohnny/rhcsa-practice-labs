#!/usr/bin/env bash
# Task: Deploy a container named "mydb" using the mysql image. Set the environment variable MYSQL_ROOT_PASSWORD=redhat123. The container must be running.
# Title: Deploy MySQL Container with Environment Variable
# Category: containers
# Target: node1

check 'podman ps --format "{{.Names}}" 2>/dev/null | grep -q "^mydb$"' \
    "Container mydb is running" \
    "Container mydb not running"

check 'podman inspect mydb --format "{{.Config.Env}}" 2>/dev/null | grep -q "MYSQL_ROOT_PASSWORD"' \
    "MYSQL_ROOT_PASSWORD is set" \
    "MYSQL_ROOT_PASSWORD not configured"
