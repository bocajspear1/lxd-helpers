#!/bin/bash

USER='jacob'

function usage {
    echo "Usage: $0 <name> <image_id> <shared_dir_path>"
    echo "image ids:"
    echo "[1] Ubuntu 18.04"
    echo "[2] Ubuntu 16.04"
    echo "[3] CentOS 7"
    echo "[4] Alpine 3.10"
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

if [ "$IMAGE_ID" -eq "1" ]; then
    echo "Creating Ubuntu 18.04 container"
    lxc init images:ubuntu/18.04 $CONT_NAME
elif [ "$IMAGE_ID" -eq "2" ]; then
    echo "Creating Ubuntu 16.04 container"
    lxc init images:ubuntu/16.04 $CONT_NAME
elif [ "$IMAGE_ID" -eq "3" ]; then
    echo "Creating CentOS 7 container"
    lxc init images:centos/7 $CONT_NAME
elif [ "$IMAGE_ID" -eq "4" ]; then
    echo "Creating Alpine 3.10 container"
    lxc init images:alpine/3.10 $CONT_NAME
fi

echo "Password for user and root (if required):"
read -s -p "> " PASSWORD
echo ""

echo "Setting up shared directory..."
lxc config device add $CONT_NAME shareddir disk path=/host source=$SHARE

echo "Starting container..."
lxc start $CONT_NAME

echo "Waiting for container DHCP..."
sleep 10

if [ "$IMAGE_ID" -eq "1" ] || [ "$IMAGE_ID" -eq "2" ]; then
    echo "Setting up Ubuntu 18.04 container"
    lxc exec $CONT_NAME -- /bin/bash -c 'apt-get update; apt-get install -y openssh-server tmux curl wget'
    lxc exec $CONT_NAME -- usermod -l $USER ubuntu
    lxc exec $CONT_NAME -- usermod -d /home/${USER} $USER
    lxc exec $CONT_NAME -- groupmod --new-name $USER ubuntu
    lxc exec $CONT_NAME -- mv /home/ubuntu /home/${USER}
    lxc exec $CONT_NAME -- /bin/bash -c "echo '${USER}:${PASSWORD}' | chpasswd"
elif [ "$IMAGE_ID" -eq "3" ]; then
    echo "Setting up CentOS 7 container"
    lxc exec $CONT_NAME -- /bin/bash -c 'yum install -y openssh-server tmux sudo curl wget'
    lxc exec $CONT_NAME -- useradd $USER
    lxc exec $CONT_NAME -- usermod -d /home/${USER} -m $USER
    lxc exec $CONT_NAME -- /bin/bash -c "echo '${PASSWORD}' | passwd --stdin ${USER}"
    lxc exec $CONT_NAME -- /bin/bash -c "echo '${PASSWORD}' | passwd --stdin root"
elif [ "$IMAGE_ID" -eq "4" ]; then
    echo "Setting up Alpine 3.10 container"
    lxc exec $CONT_NAME -- /bin/ash -c 'apk update; apk add openssh-server tmux sudo wget curl'
    lxc exec $CONT_NAME -- adduser -D -h /home/${USER} ${USER}
    lxc exec $CONT_NAME -- /bin/ash -c "echo '${USER}:${PASSWORD}' | chpasswd"
    lxc exec $CONT_NAME -- /bin/ash -c "echo 'root:${PASSWORD}' | chpasswd"
    lxc exec $CONT_NAME -- /bin/ash -c "echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers"
    lxc exec $CONT_NAME -- adduser jacob wheel
fi

echo "Entering container..."
if [ "$IMAGE_ID" -eq "3" ]; then
    lxc exec -t $CONT_NAME -- sudo --login --user ${USER} bash
else
    lxc exec -t $CONT_NAME -- sudo --login --user ${USER} tmux
fi