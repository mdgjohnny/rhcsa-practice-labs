#!/usr/bin/env bash
# Task: Start a long-running background process (sleep 99999 &), then find and terminate it using the kill command.
# Title: Find and Kill Process
# Category: operate-systems
# Target: node1

check '! pgrep -f "sleep 99999" >/dev/null' \
    "Sleep process has been terminated" \
    "Sleep process is still running (use ps/pgrep to find, kill to terminate)"
