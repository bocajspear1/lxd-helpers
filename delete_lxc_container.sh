#!/bin/bash

function usage {
    echo "Usage: $0 <name> "
    exit 1
}

if [ -z "$1" ]; then
    echo "No container name given"
    usage
fi

CONT_NAME=$1

lxc stop $CONT_NAME
lxc delete $CONT_NAME