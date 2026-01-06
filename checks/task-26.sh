#!/usr/bin/env bash
# Task: Cron for user70: find "core" in /var, copy to /var/tmp/coredir1, every Monday 1:20 AM
# Category: deploy-maintain

check \'run_ssh "$NODE1_IP" "test -d /var/tmp/coredir1"\' \
    "Directory /var/tmp/coredir1 exists" \
    "Directory /var/tmp/coredir1 does not exist"

check \'run_ssh "$NODE1_IP" "crontab -u user70 -l 2>/dev/null | grep -q "20 1.*\* \* 1\|20 1.*\* \* Mon""\' \
    "Cron job for user70 runs Monday at 1:20" \
    "Cron job for user70 not configured correctly"

check \'run_ssh "$NODE1_IP" "crontab -u user70 -l 2>/dev/null | grep -q "core""\' \
    "Cron job searches for 'core' files" \
    "Cron job does not search for 'core' files"
