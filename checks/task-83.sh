#!/usr/bin/env bash
# Task: Create sales/account groups with joana/john in sales, laura/beatrix in account
# Title: Create Users in Groups (sales/account)
# Category: users-groups
# Target: node1

# Check if groups exist
check 'getent group sales &>/dev/null' \
    "Group sales exists" \
    "Group sales does not exist"

check 'getent group account &>/dev/null' \
    "Group account exists" \
    "Group account does not exist"

# Check if users exist with private primary groups
check 'id joana &>/dev/null && [[ $(id -gn joana) == "joana" ]]' \
    "User joana exists with private primary group" \
    "User joana missing or wrong primary group"

check 'id john &>/dev/null && [[ $(id -gn john) == "john" ]]' \
    "User john exists with private primary group" \
    "User john missing or wrong primary group"

check 'id laura &>/dev/null && [[ $(id -gn laura) == "laura" ]]' \
    "User laura exists with private primary group" \
    "User laura missing or wrong primary group"

check 'id beatrix &>/dev/null && [[ $(id -gn beatrix) == "beatrix" ]]' \
    "User beatrix exists with private primary group" \
    "User beatrix missing or wrong primary group"

# Check secondary group memberships
check 'id joana 2>/dev/null | grep -q "sales"' \
    "User joana is member of sales" \
    "User joana is not member of sales"

check 'id john 2>/dev/null | grep -q "sales"' \
    "User john is member of sales" \
    "User john is not member of sales"

check 'id laura 2>/dev/null | grep -q "account"' \
    "User laura is member of account" \
    "User laura is not member of account"

check 'id beatrix 2>/dev/null | grep -q "account"' \
    "User beatrix is member of account" \
    "User beatrix is not member of account"

# Check /shared directory
check '[[ -d /shared ]]' \
    "Directory /shared exists" \
    "Directory /shared does not exist"
