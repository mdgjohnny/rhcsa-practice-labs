#!/usr/bin/env bash
# Task: A sleep process is running in the background with a very long duration. Find and terminate it using the kill command. The process was started as: sleep 99999 &
# Title: Find and Kill Process
# Category: operate-systems
# Target: node1
# Setup: sleep 99999 &

# Note: The grader will start the process before checking

check '! pgrep -f "sleep 99999" >/dev/null' \
    "Sleep process has been terminated" \
    "Sleep process is still running (use ps/pgrep to find, kill to terminate)"
