#!/usr/bin/env bash
# Task: Configure network on node1 with IP, gateway, and DNS

IPV4_ADDR="${IPV4_ADDR:-192.168.0.241/24}"
IPV4_GW="${IPV4_GW:-192.168.0.1}"
IPV4_DNS="${IPV4_DNS:-192.168.0.1}"

IPV4_ADDR_LOCAL=$(hostname -I | awk '{print $1}')
IPV4_GW_LOCAL=$(ip route show default | awk '/default/ {print $3}')
IPV4_DNS_LOCAL=$(awk '/nameserver/{print $2; exit}' /etc/resolv.conf)

check '[[ "$IPV4_ADDR_LOCAL" == "$IPV4_ADDR" ]]' \
    "IPv4 address set to $IPV4_ADDR" \
    "IPv4 address not set to $IPV4_ADDR (got $IPV4_ADDR_LOCAL)"

check '[[ "$IPV4_GW_LOCAL" == "$IPV4_GW" ]]' \
    "IPv4 gateway set to $IPV4_GW" \
    "IPv4 gateway not set to $IPV4_GW (got $IPV4_GW_LOCAL)"

check '[[ "$IPV4_DNS_LOCAL" == "$IPV4_DNS" ]]' \
    "IPv4 DNS set to $IPV4_DNS" \
    "IPv4 DNS not set to $IPV4_DNS (got $IPV4_DNS_LOCAL)"
