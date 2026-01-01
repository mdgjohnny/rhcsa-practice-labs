#!/usr/bin/env bash
# Task: Configure passwordless SSH for user100 from rhcsa1 to rhcsa2
# Category: security
# Copy /etc/sysconfig to rhcsa2:/var/tmp/remote

check 'su - user100 -c "ssh -o BatchMode=yes -o ConnectTimeout=5 $NODE2_IP exit" &>/dev/null' \
    "user100 can SSH to node2 without password" \
    "user100 cannot SSH to node2 without password"

check 'run_ssh "$NODE2_IP" "[[ -d /var/tmp/remote ]]" 2>/dev/null' \
    "/var/tmp/remote directory exists on node2" \
    "/var/tmp/remote does not exist on node2"

check 'run_ssh "$NODE2_IP" "ls /var/tmp/remote/ | wc -l" 2>/dev/null | grep -qv "^0$"' \
    "/var/tmp/remote contains files on node2" \
    "/var/tmp/remote is empty on node2"
