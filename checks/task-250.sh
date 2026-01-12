#!/usr/bin/env bash
# Task: Create /root/calculator.sh that takes two numbers and an operator (+,-,*,/) as arguments and outputs the result.
# Title: Shell Script - Multiple Arguments Calculator
# Category: shell-scripts
# Target: node1

check '[[ -x /root/calculator.sh ]]' \
    "Script exists and is executable" \
    "Script missing or not executable"

check 'grep -qE "\\\$1.*\\\$2.*\\\$3|\\\$1.*\\\$3.*\\\$2" /root/calculator.sh' \
    "Script uses multiple positional parameters" \
    "Script doesn't use $1, $2, $3"

check 'result=$(/root/calculator.sh 10 + 5 2>/dev/null); [[ "$result" =~ 15 ]]' \
    "Script calculates 10 + 5 = 15" \
    "Calculator doesn't work correctly"
