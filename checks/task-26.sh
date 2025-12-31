#!/usr/bin/env bash
# Task: Cron job for user70 to find "core" files in /var
# and copy to /var/tmp/coredir1, every Monday at 1:20 AM

check '[[ -d /var/tmp/coredir1 ]]' \
    "Directory /var/tmp/coredir1 exists" \
    "Directory /var/tmp/coredir1 does not exist"

check 'crontab -u user70 -l 2>/dev/null | grep -q "20 1.*\* \* 1\|20 1.*\* \* Mon"' \
    "Cron job for user70 runs Monday at 1:20" \
    "Cron job for user70 not configured correctly"

check 'crontab -u user70 -l 2>/dev/null | grep -q "core"' \
    "Cron job searches for 'core' files" \
    "Cron job does not search for 'core' files"
