#!/usr/bin/env bash
# Task: Create cron job for user70: find files named "core" in /var, copy to /var/tmp/coredir1, run Mon 1:20 AM.
# Title: Schedule Cron Job
# Category: deploy-maintain
# Target: node1

check '[[ -d /var/tmp/coredir1 ]]' \
    "Directory /var/tmp/coredir1 exists" \
    "Directory /var/tmp/coredir1 does not exist"

check 'crontab -u user70 -l 2>/dev/null | grep -q "20 1.*\* \* 1\|20 1.*\* \* Mon"' \
    "Cron job for user70 runs Monday at 1:20" \
    "Cron job for user70 not configured correctly"

check 'crontab -u user70 -l 2>/dev/null | grep -q "core"' \
    "Cron job searches for 'core' files" \
    "Cron job does not search for 'core' files"
