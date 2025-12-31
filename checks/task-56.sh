#!/usr/bin/env bash
# Task: Set tuned profile to powersave

ACTIVE_PROFILE=$(tuned-adm active 2>/dev/null | awk '{print $NF}')

check '[[ "$ACTIVE_PROFILE" == "powersave" ]]' \
    "Tuned profile is powersave" \
    "Tuned profile is not powersave (got $ACTIVE_PROFILE)"
