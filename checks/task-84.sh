#!/usr/bin/env bash
# Task: Create user "bill". Configure sudo so bill can run /usr/sbin/useradd, /usr/sbin/usermod, and /usr/bin/passwd but NOT /usr/bin/passwd root (cannot change root password).
# Title: Configure Limited Sudo Access
# Category: users-groups
# Target: node1

check 'id bill &>/dev/null' \
    "User bill exists" \
    "User bill does not exist"

check 'grep -rqE "bill.*(useradd|usermod|passwd)" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \
    "Bill has user management sudo rules" \
    "Bill missing user management permissions"

# Check that passwd root is explicitly denied or not granted
check 'grep -rqE "bill.*!/usr/bin/passwd.*root|bill.*NOPASSWD.*passwd,.*!.*passwd root" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \
    "Bill cannot change root password" \
    "Need to deny bill from running 'passwd root'"
