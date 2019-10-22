#!/bin/bash

USER='jacob'

function usage {
    echo "Usage: $0 <name> "
    exit 1
}

if [ -z "$1" ]; then
    echo "No container name given"
    usage
fi

cont_name=$1

lxc exec -t $cont_name -- sudo --login --user ${USER} tmux