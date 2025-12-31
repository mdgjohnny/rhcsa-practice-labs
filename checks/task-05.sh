#!/usr/bin/env bash
# Task: Ping both node1 and node2
# Assumes $NODE1 and $NODE2 have hostnames correctly set-up

is_alive() {
    ping -c1 "$1" &> /dev/null
}

check 'is_alive "$NODE1"' \
    "Node 1 is reachable at $NODE1" \
    "Node 1 is not reachable at $NODE1"

check 'is_alive "$NODE2"' \
    "Node 2 is reachable at $NODE2" \
    "Node 2 is not reachable at $NODE2"
