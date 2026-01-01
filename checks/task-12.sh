#!/usr/bin/env bash
# Task: Create /groups/dbadmin and /groups/accounting with setgid, no access for others
# Category: file-systems

check '[[ -d /groups/dbadmin ]]' \
    "Directory /groups/dbadmin exists" \
    "Directory /groups/dbadmin does not exist"

check '[[ -d /groups/accounting ]]' \
    "Directory /groups/accounting exists" \
    "Directory /groups/accounting does not exist"

check 'stat -c %G /groups/dbadmin | grep -q dbadmin' \
    "/groups/dbadmin is group-owned by dbadmin" \
    "/groups/dbadmin is not group-owned by dbadmin"

check 'stat -c %G /groups/accounting | grep -q accounting' \
    "/groups/accounting is group-owned by accounting" \
    "/groups/accounting is not group-owned by accounting"

check 'stat -c %a /groups/dbadmin | grep -q "^2..0$"' \
    "/groups/dbadmin has setgid and no other access" \
    "/groups/dbadmin permissions incorrect (need setgid, no others)"

check 'stat -c %a /groups/accounting | grep -q "^2..0$"' \
    "/groups/accounting has setgid and no other access" \
    "/groups/accounting permissions incorrect (need setgid, no others)"
