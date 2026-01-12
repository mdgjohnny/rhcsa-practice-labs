#!/usr/bin/env bash
# Task: Document the rd.break root password recovery procedure. Create /root/recovery-procedure.txt with the exact steps.
# Title: Document Root Password Recovery
# Category: operate-systems
# Target: node1

check '[[ -f /root/recovery-procedure.txt ]]' \
    "Recovery procedure file exists" \
    "File not found"

check 'grep -qi "rd.break" /root/recovery-procedure.txt' \
    "Procedure mentions rd.break" \
    "rd.break not mentioned"

check 'grep -qi "sysroot" /root/recovery-procedure.txt' \
    "Procedure mentions sysroot mount" \
    "sysroot not mentioned"

check 'grep -qi "chroot\|passwd\|autorelabel" /root/recovery-procedure.txt' \
    "Procedure includes chroot/passwd/autorelabel" \
    "Key steps missing"
