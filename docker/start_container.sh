#!/bin/bash
containerName="dev"
docker start $containerName
docker exec -it \
    -e COLUMNS=$(tput cols) \
    -e LINES=$(tput lines) \
    -e DISPLAY=$DISPLAY \
    $containerName bash