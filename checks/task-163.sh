#!/usr/bin/env bash
# Task: Create a script /root/filetype.sh that accepts a path as argument and reports whether it is a "regular file", "directory", "symbolic link", or "other". Use test operators or [[ ]].
# Title: Shell Script - File Type Checker
# Category: shell-scripts
# Target: node1

check '[[ -f /root/filetype.sh ]]' \
    "Script /root/filetype.sh exists" \
    "Script /root/filetype.sh not found"

check '[[ -x /root/filetype.sh ]]' \
    "Script is executable" \
    "Script is not executable"

check 'head -1 /root/filetype.sh | grep -qE "^#!"' \
    "Script has shebang line" \
    "Script missing shebang line"

check 'grep -qE "(-f |-d |-L |-h )" /root/filetype.sh || grep -qE "\[\[.*-f|\[\[.*-d|\[\[.*-L" /root/filetype.sh' \
    "Script uses file test operators (-f, -d, -L)" \
    "Script missing file test operators"

check 'grep -qE "\\\$1|\\\${1}" /root/filetype.sh' \
    "Script uses positional parameter \$1" \
    "Script missing positional parameter"

check '/root/filetype.sh /etc/passwd 2>/dev/null | grep -qi "regular\|file"' \
    "Script identifies regular file correctly" \
    "Script fails for regular file"

check '/root/filetype.sh /etc 2>/dev/null | grep -qi "directory\|dir"' \
    "Script identifies directory correctly" \
    "Script fails for directory"

check 'ln -sf /etc/passwd /tmp/testlink_163 && /root/filetype.sh /tmp/testlink_163 2>/dev/null | grep -qi "link\|symbolic"' \
    "Script identifies symbolic link correctly" \
    "Script fails for symbolic link"
