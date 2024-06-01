#!/bin/bash

# Docker development environment
# This script builds a Docker image with a specified base image and creates a user inside the container.
# The user created inside the container will have the same username and user ID as the host user.
# The script also sets up the necessary directories, permissions, and environment variables for the user.
# Additionally, it adds the user to the "dialout" group and sets the working directory for subsequent commands.

echo "Running docker build"

# Base image to use for the Docker image
BASE_IMAGE="base_image"

# Get the user ID of the host user
USERID=$(id -u)

# Name of the Docker image to be built
DOCKER_IMAGE="dev-${USER}"
containerName="dev-${USER}"

# Build a Docker image with the specified base image and create a user inside the container
docker build -t $DOCKER_IMAGE - << EOF
FROM $BASE_IMAGE

# Create a user with the same username and user ID as the host user
RUN useradd -ms /bin/bash $USER -u $USERID
ARG DEBIAN_FRONTEND=noninteractive

# Create the necessary directories and set up the user in the container
RUN  mkdir -p /home/$USER && mkdir -p /home/$USER/.cache && \
    echo "$USER:x:1000:1000:$USER,,,:/home/$USER:/bin/bash" >> /etc/passwd && \
    echo "$USER:x:1000:" >> /etc/group && \
    echo "docker:x:$DOCKER_GROUP:$USER" >> /etc/group && \
    echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER && \
    ls /etc/sudo* &&\
    chmod 0440 /etc/sudoers.d/$USER && \
    chown $USER:$USER -R /home/$USER

# Add the user to the "dialout" group
RUN usermod -a -G dialout $USER

# Set the user and working directory for subsequent commands
USER $USER
ENV HOME /home/$USER
WORKDIR /home/$USER/                                                    # Choose the working directory
ENV PS1 '\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

EOF

echo "Docker build complete"


# ______________________________________________________________________________________________________________________ #
# Now time to create the container

#!/bin/bash

echo "Running docker create"

DOCKER_IMAGE_ID=$(docker inspect --format="{{range .RepoDigests}}{{println .}}{{end}}" $DOCKER_IMAGE)
if [ -z "$DOCKER_IMAGE_ID" ]; then
  DOCKER_IMAGE_ID=$(docker inspect --format="$DOCKER_IMAGE@{{.ContainerConfig.Image}}" $DOCKER_IMAGE)
fi

# according to https://forums.docker.com/t/docker-and-udev-events/5472 "--net host" and "-v /dev:/dev" are needed for docker to detect udev usb event.
# this allows to reset and replug usb devices.

IT_ARG="-it"


# Check if /mnt is a directory, if so bind mount it
if [ -d /mnt ]; then
    MNT_STORE="--mount type=bind,source=/mnt,target=/mnt,bind-propagation=shared"
else
    MNT_STORE=""
fi

# Check if /media is a directory, if so bind mount it
if [ -d /media ]; then
  MOUNT_MEDIA="--mount type=bind,source=/media,target=/media,bind-propagation=slave"
else
  MOUNT_MEDIA=""
fi

docker create $IT_ARG \
  --runtime=nvidia \
  --name $containerName \
  --net host \
  ${USE_LOCAL_DNS} \
  --privileged \
  --shm-size 4G \
  --user $USER \
  $MOUNT_MEDIA \
  $MNT_STORE \
  -v /run/udev:/run/udev:ro \
  -v $HOME/:$HOME \
  -v /dev:/dev \
  -v /usr/share/code:/usr/share/code \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /etc/localtime:/etc/localtime \
  -v /run/systemd/system:/run/systemd/system \
  -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
  -v /var/run/:/host_var_run/:ro \
  -v /etc/timezone:/etc/timezone \
  -v /var/run/dbus:/var/run/dbus \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e DISPLAY=$DISPLAY \
  -e CONTAINER_NAME=$containerName \
  -e DOCKER_IMAGE_ID=$DOCKER_IMAGE_ID \
  $DOCKER_IMAGE 2> >(grep -v "WARNING: Localhost DNS setting" 1>&2)
