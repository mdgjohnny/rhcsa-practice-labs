#!/usr/bin/env bash
# Task: Schedule a task that runs the command touch /etc/motd every day from Monday through Friday at 2 a.m
# Category: operate-systems
# Target: node1


check 'crontab -l 2>/dev/null | grep -q . || ls /etc/cron.d/* 2>/dev/null | grep -q .' \
    "Cron job is configured" \
    "No cron job found"
