#!/usr/bin/env bash
# Task: Set the tuned profile to "powersave" for power optimization.
# Title: Set Powersave Tuned Profile
# Category: operate-systems

ACTIVE_PROFILE=$(tuned-adm active 2>/dev/null | awk '{print $NF}')

check '[[ "$ACTIVE_PROFILE" == "powersave" ]]' \
    "Tuned profile is powersave" \
    "Tuned profile is not powersave (got $ACTIVE_PROFILE)"
