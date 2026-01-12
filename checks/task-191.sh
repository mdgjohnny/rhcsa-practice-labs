#!/usr/bin/env bash
# Task: Create /root/countdown.sh that takes a number as argument and counts down from that number to 1, printing each number on a new line. Use a while loop.
# Title: Shell Script - While Loop Countdown
# Category: shell-scripts
# Target: node1

check '[[ -x /root/countdown.sh ]]' \
    "Script /root/countdown.sh exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "while " /root/countdown.sh' \
    "Script uses while loop" \
    "Script doesn't use while loop"

check 'output=$(/root/countdown.sh 5 2>/dev/null); echo "$output" | grep -q "5" && echo "$output" | grep -q "1"' \
    "Script counts down correctly (5 to 1)" \
    "Script doesn't count down correctly"

check '[[ $(/root/countdown.sh 3 2>/dev/null | wc -l) -eq 3 ]]' \
    "Script outputs correct number of lines" \
    "Script output has wrong number of lines"
