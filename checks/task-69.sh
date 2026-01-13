#!/usr/bin/env bash
# Task: As user user20, run a ubi9 container named "myubi" with environment variables SHELL=/bin/bash and HOSTNAME=container20. Create a systemd user service to start it at boot. Enable lingering for user20.
# Title: Container with Environment Variables
# Category: containers
# Target: node1


check 'id user20 &>/dev/null' \
    "User user20 exists" \
    "User user20 does not exist"

check 'loginctl show-user user20 2>/dev/null | grep -q "Linger=yes"' \
    "Linger enabled for user20" \
    "Linger not enabled for user20"

check 'sudo runuser -l user20 -c "podman ps -a" 2>/dev/null | grep -q myubi' \
    "Container myubi exists" \
    "Container myubi does not exist"

check 'sudo runuser -l user20 -c "podman inspect myubi --format \"{{.Config.Env}}\"" 2>/dev/null | grep -q "SHELL=/bin/bash"' \
    "Container has SHELL environment variable" \
    "Container missing SHELL environment variable"

check 'sudo runuser -l user20 -c "podman inspect myubi --format \"{{.Config.Env}}\"" 2>/dev/null | grep -q "HOSTNAME=container20"' \
    "Container has HOSTNAME environment variable" \
    "Container missing HOSTNAME environment variable"

check 'sudo runuser -l user20 -c "export XDG_RUNTIME_DIR=/run/user/\$(id -u); systemctl --user is-enabled container-myubi || systemctl --user is-enabled myubi" &>/dev/null' \
    "Systemd user service is enabled" \
    "Systemd user service is not enabled"
