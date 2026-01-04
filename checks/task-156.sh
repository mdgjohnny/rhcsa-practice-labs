#!/usr/bin/env bash
# Task: Write a bash shell script to create three user accounts— user555, user666, and user777—with no login shell and passwords matching their usernames. The script should also extract the three usernames from the /etc/passwd file and redirect them into /var/tmp/newusers
# Category: users-groups
# Target: node1

# Check users exist
check 'id user555 &>/dev/null' \
    "User user555 exists" \
    "User user555 does not exist"

check 'id user666 &>/dev/null' \
    "User user666 exists" \
    "User user666 does not exist"

check 'id user777 &>/dev/null' \
    "User user777 exists" \
    "User user777 does not exist"

# Check users have nologin shell
check 'getent passwd user555 | grep -q "nologin\|/bin/false"' \
    "user555 has no login shell" \
    "user555 has a login shell"

check 'getent passwd user666 | grep -q "nologin\|/bin/false"' \
    "user666 has no login shell" \
    "user666 has a login shell"

check 'getent passwd user777 | grep -q "nologin\|/bin/false"' \
    "user777 has no login shell" \
    "user777 has a login shell"

# Check output file exists
check '[[ -f /var/tmp/newusers ]]' \
    "File /var/tmp/newusers exists" \
    "File /var/tmp/newusers does not exist"

# Check output file contains the usernames
check 'grep -q "user555" /var/tmp/newusers && grep -q "user666" /var/tmp/newusers && grep -q "user777" /var/tmp/newusers' \
    "/var/tmp/newusers contains all three usernames" \
    "/var/tmp/newusers missing some usernames"
