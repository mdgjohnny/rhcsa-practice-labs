#!/usr/bin/env bash
NODE1="${NODE1:-rhcsa1}"
IPV4_ADDR="${IP4_ADDR:-192.168.0.241/24}"
IPV4_GW="${IP4_GW:-192.168.0.1}"
IPV4_DNS="${IP4_DNS:-192.168.0.1}"
# Ensure node1 has configured IP addresses based on lab setup

IPV4_ADDR_LOCAL=$(hostname -I | awk '{print $1}')
IPV4_GW_LOCAL=$(ip route show default | awk '/default/ {print $3}')
IPV4_DNS=$(awk '/nameserver/{print $2}' /etc/resolv.conf)

if [[ "$IPV4_ADDR_LOCAL" -eq "$IPV4_ADDR" ]]; then
    echo -e "${GREEN}[OK]${NC} IPv4 address set to $IPV4_ADDR"
    SCORE=$(( SCORE + 10 ))
else
    echo -e "${RED}[FAIL]${NC} IPv4 address not set to $IPV4_ADDR"
fi
TOTAL=$(( TOTAL + 10 ))

if [[ "$IPV4_GW" -eq "$IPV4_GW_LOCAL" ]]; then
    echo -e "${GREEN}[OK]${NC} IPv4 gateway set to $IPV4_GW_LOCAL"
    SCORE=$(( SCORE + 10 ))
else
    echo -e "${RED}[FAIL]${NC} IPv4 gateway not set to $IPV4_GW_LOCAL"
fi
TOTAL=$(( TOTAL + 10 ))

if [[ "$IPV4_DNS" -eq "$IPV4_DNS_LOCAL" ]]; then
    echo -e "${GREEN}[OK]${NC} IPv4 DNS set to $IPV4_DNS_LOCAL"
    SCORE=$(( SCORE + 10 ))
else
    echo -e "${RED}[FAIL]${NC} IPv4 DNS not set to $IPV4_DNS_LOCAL"
fi
TOTAL=$(( TOTAL + 10 ))
