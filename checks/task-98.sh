#!/usr/bin/env bash
# Task: Create a cron job that runs "touch /etc/motd" every weekday (Monday through Friday) at 2:00 AM.
# Title: Schedule Weekday Cron Job
# Category: operate-systems
# Target: node1

# Check for cron entry with correct time (0 2 = 2:00 AM)
check 'crontab -l 2>/dev/null | grep -E "0 2 .* \* 1-5|0 2 .* \* Mon-Fri" | grep -q "motd" || grep -rE "0 2 .* \* 1-5|0 2 .* \* Mon-Fri" /etc/cron.d/ 2>/dev/null | grep -q "motd"' \
    "Cron job scheduled for 2:00 AM weekdays" \
    "Cron job not found or wrong schedule"

# Check the command references motd
check 'crontab -l 2>/dev/null | grep -q "touch.*/etc/motd\|/etc/motd" || grep -rq "touch.*/etc/motd\|/etc/motd" /etc/cron.d/ 2>/dev/null' \
    "Cron job touches /etc/motd" \
    "Command doesn't reference /etc/motd"
