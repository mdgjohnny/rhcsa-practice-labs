#!/bin/bash

NODE_NAME="{$NODE_NAME:-rhcsa2}"

ssh root@"$NODENAME" exit

RETURN_STATUS=$?

if [[ "$RETURN_STATUS" -ne 0 ]]; then
    echo "Cannot SSH as root into $NODENAME" >&2
    exit 1
else
    echo "Logged successfully as root into $NODENAME"
fi
