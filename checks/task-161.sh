#!/usr/bin/env bash
# Task: Create a script /root/greet.sh that takes multiple names as arguments and prints "Hello, <name>!" for each one. Use a loop to process all arguments.
# Title: Shell Script - Process Multiple Arguments
# Category: shell-scripts
# Target: node1

check '[[ -f /root/greet.sh ]]' \
    "Script /root/greet.sh exists" \
    "Script /root/greet.sh not found"

check '[[ -x /root/greet.sh ]]' \
    "Script is executable" \
    "Script is not executable"

check 'head -1 /root/greet.sh | grep -qE "^#!"' \
    "Script has shebang line" \
    "Script missing shebang line"

check 'grep -qE "(for |while )" /root/greet.sh' \
    "Script uses a loop construct (for/while)" \
    "Script missing loop construct"

check 'grep -qE "\\\$@|\\\$\*|\"\\\$@\"" /root/greet.sh' \
    "Script processes all arguments (\$@ or \$*)" \
    "Script doesn't handle multiple arguments"

check '/root/greet.sh Alice 2>/dev/null | grep -q "Hello.*Alice"' \
    "Script greets single argument correctly" \
    "Script fails for single argument"

check 'output=$(/root/greet.sh Alice Bob Carol 2>/dev/null) && echo "$output" | grep -q "Alice" && echo "$output" | grep -q "Bob" && echo "$output" | grep -q "Carol"' \
    "Script greets all three names" \
    "Script fails to greet all arguments"
