#!/usr/bin/env bash
# Task: Configure /etc/hosts so node1 can ping rhcsa2 by hostname and node2 can ping rhcsa1 by hostname
# Title: Configure /etc/hosts
# Category: networking
# Target: both

# Check from node1: can ping node2 by hostname
check 'run_ssh "$NODE1_IP" "ping -c1 rhcsa2" 2>/dev/null | grep -q "1 received"' \
    "Node1 can ping rhcsa2 by hostname" \
    "Node1 cannot ping rhcsa2 by hostname (check /etc/hosts on node1)"

# Check from node2: can ping node1 by hostname
check 'run_ssh "$NODE2_IP" "ping -c1 rhcsa1" 2>/dev/null | grep -q "1 received"' \
    "Node2 can ping rhcsa1 by hostname" \
    "Node2 cannot ping rhcsa1 by hostname (check /etc/hosts on node2)"
