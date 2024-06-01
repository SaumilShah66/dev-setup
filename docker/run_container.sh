#!/bin/bash
containerName="dev"

# Check if the container is running, if not start it
[ ! "$(docker ps -aq -f name=$containerName -f status=running)" ] && docker start $containerName >/dev/null

# Execute shell in the container and start a bash session
docker exec -it -e COLUMNS=$(tput cols) -e LINES=$(tput lines) -w=$PWD $containerName bash "$@"