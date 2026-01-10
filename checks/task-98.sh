#!/usr/bin/env bash
# Task: Create cron job to run "touch /etc/motd" Monday through Friday at 2:00 AM.
# Title: Schedule Cron Job
# Category: operate-systems
# Target: node1


check 'crontab -l 2>/dev/null | grep -q . || ls /etc/cron.d/* 2>/dev/null | grep -q .' \
    "Cron job is configured" \
    "No cron job found"
