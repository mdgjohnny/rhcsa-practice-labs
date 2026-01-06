#!/usr/bin/env bash
# Task: Schedule cron job to run 'touch /etc/motd' Mon-Fri at 2am
# Category: operate-systems
# Target: node1


check 'crontab -l 2>/dev/null | grep -q . || ls /etc/cron.d/* 2>/dev/null | grep -q .' \
    "Cron job is configured" \
    "No cron job found"
