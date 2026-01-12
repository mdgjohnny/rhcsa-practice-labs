#!/usr/bin/env bash
# Task: Create a script /root/backup.sh that creates a compressed tar archive of /etc in /root/backups/ with filename backup-YYYYMMDD.tar.gz (using current date). Create /root/backups if it doesn't exist.
# Title: Shell Script - Backup with Date
# Category: shell-scripts
# Target: node1

check '[[ -f /root/backup.sh ]]' \
    "Script /root/backup.sh exists" \
    "Script /root/backup.sh not found"

check '[[ -x /root/backup.sh ]]' \
    "Script is executable" \
    "Script is not executable"

check 'head -1 /root/backup.sh | grep -qE "^#!"' \
    "Script has shebang line" \
    "Script missing shebang line"

check 'grep -qE "\\\$\(date|\`date" /root/backup.sh' \
    "Script uses date command substitution" \
    "Script missing date command"

check 'grep -qE "tar.*czf|tar.*-czf|tar.*zcf" /root/backup.sh' \
    "Script uses tar with gzip compression" \
    "Script missing tar compression"

check '/root/backup.sh 2>/dev/null; [[ -d /root/backups ]]' \
    "Script creates /root/backups directory" \
    "Script fails to create backup directory"

check 'today=$(date +%Y%m%d); /root/backup.sh 2>/dev/null; [[ -f /root/backups/backup-${today}.tar.gz ]]' \
    "Script creates backup with correct date format" \
    "Backup file with today's date not found"

check 'today=$(date +%Y%m%d); tar tzf /root/backups/backup-${today}.tar.gz 2>/dev/null | grep -q "etc/"' \
    "Backup archive contains /etc contents" \
    "Backup archive doesn't contain /etc"
