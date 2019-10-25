#!/bin/bash

USER='jacob'

function usage {
    echo "Usage: $0 <name> <image_id> <shared_dir_path>"
    echo "image ids:"
    echo "[1] Ubuntu 18.04"
    echo "[2] Ubuntu 16.04"
    exit 1
}

if [ -z "$1" ]; then
    echo "No container name given"
    usage
fi

if [ -z "$2" ]; then
    echo "No image id given"
    usage
fi

if [ -z "$3" ]; then
    echo "No shared directory path given"
    usage
fi

CONT_NAME=$1
IMAGE_ID=$2
SHARE=$3

# From https://stackoverflow.com/a/246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Ensure profile exists
lxc profile get lxdgui raw.idmap 2>/dev/null >/dev/null
if [ "$?" -ne "0" ]; then 
    echo "Creating profile"
    lxc profile create lxdgui
    cat ${DIR}/lxdgui-profile.txt | lxc profile edit lxdgui
fi

# Create the container itself
if [ "$IMAGE_ID" -eq "1" ]; then
    echo "Creating Ubuntu 18.04 container"
    lxc init --profile default --profile lxdgui images:ubuntu/18.04 $CONT_NAME
elif [ "$IMAGE_ID" -eq "2" ]; then
    echo "Creating Ubuntu 16.04 container"
    lxc init --profile default --profile lxdgui images:ubuntu/16.04 $CONT_NAME
else
    echo "Invalid image id"
    exit 1
fi

echo "Password for user '$USER' and root (if required):"
read -s -p "> " PASSWORD
echo ""

echo "Ensuring access to display"
xhost +local:

echo "Setting up shared directory..."
lxc config device add $CONT_NAME shareddir disk path=/host source=$SHARE

echo "Starting container..."
lxc start $CONT_NAME

echo "Waiting for container DHCP..."
sleep 10

if [ "$IMAGE_ID" -eq "1" ] || [ "$IMAGE_ID" -eq "2" ]; then
    echo "Setting up Ubuntu 18.04 container"
    lxc exec $CONT_NAME -- /bin/bash -c 'apt-get update; apt-get install -y openssh-server curl wget x11-apps mesa-utils pulseaudio firefox'
    lxc exec $CONT_NAME -- usermod -l $USER ubuntu
    lxc exec $CONT_NAME -- usermod -d /home/${USER} $USER
    lxc exec $CONT_NAME -- groupmod --new-name $USER ubuntu
    lxc exec $CONT_NAME -- mv /home/ubuntu /home/${USER}
    lxc exec $CONT_NAME -- /bin/bash -c "echo '${USER}:${PASSWORD}' | chpasswd"
    lxc exec $CONT_NAME -- sed -i "s/; enable-shm = yes/enable-shm = no/g" /etc/pulse/client.conf
    lxc exec $CONT_NAME -- /bin/bash -c "echo export PULSE_SERVER=unix:/tmp/.pulse-native | tee --append /home/${USER}/.profile"
else
    echo "Invalid image"
    exit 1
fi

echo "Entering container..."
echo ""
echo "!!! - Commands like 'sudo' and 'su' won't work due to this not really being a real tty. Use SSH for better CLI access."
echo ""
lxc exec -t $CONT_NAME -- sudo --login --user ${USER} bash
