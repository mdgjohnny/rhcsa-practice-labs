#!/usr/bin/env bash
# Task: Search the audit log for AVC (SELinux access denied) messages and save the output to /root/denials.txt. Include only lines containing 'avc:' or 'AVC'.
# Title: Search Audit Log for SELinux Denials
# Category: security
# Target: node1

check '[[ -f /root/denials.txt ]]' \
    "File /root/denials.txt exists" \
    "File /root/denials.txt not found"

check '[[ -s /root/denials.txt ]] || ausearch -m avc 2>/dev/null | head -1 | grep -q "no matches"' \
    "File has content or no denials exist" \
    "File is empty but there may be denials in audit log"

# If denials exist in system, verify file format looks like audit output
check 'grep -qE "avc:|AVC|type=AVC" /root/denials.txt 2>/dev/null || [[ ! -s /root/denials.txt ]]' \
    "Output contains AVC records or is empty (no denials)" \
    "File doesn't appear to contain SELinux denial records"
