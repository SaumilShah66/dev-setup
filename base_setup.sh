#! /bin/bash

# Some colors for the output
set -e
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'


function cmd() {
  echo -e "$ ${GREEN}$1${NOCOLOR}"
  $1
}

function fail() {
  echo -e "${RED}$1${NOCOLOR}"
  exit 1
}

function running_in_docker() {
  (awk -F/ '$2 == "docker"' /proc/self/cgroup | read non_empty_input)
}

MACHINE_TYPE=$(uname -m)
if [ ${MACHINE_TYPE} == 'aarch64' ]; then
  fail "This script is only valid for x86_64 architecture. Jetson platforms should be flashed with vsystem"
fi

if running_in_docker; then
  fail "This script must be run from the host (not inside Docker)"
fi

OS=$(
  . /etc/os-release
  echo "${NAME} ${VERSION}"
)
echo -e "Setting up ${GREEN}${OS}${NOCOLOR} environment for ${GREEN}$(whoami)${NOCOLOR}"

# Install common and required packages
cmd "sudo apt update"
cmd "sudo apt install -y build-essential curl wget git git-lfs terminator vim tmux net-tools htop docker.io gnupg-agent python3-pip resolvconf"
cmd "sudo -H pip3 install pre-commit"

# Install google chrome
cmd "wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
cmd "sudo dpkg -i google-chrome-stable_current_amd64.deb"
cmd "rm google-chrome-stable_current_amd64.deb"

# Install VS Code
cmd "sudo snap install --classic code" #

# Install sublime text and sublime merge
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
cmd "sudo apt-get update"
cmd "sudo apt-get install apt-transport-https -y"
cmd "sudo apt-get install sublime-text -y"
cmd "sudo snap install sublime-merge --classic"

# Setup git so that local branch names match upstream branch names
# This is useful for PRs and for keeping track of the branch you are working on
cmd "git config --global push.default current"

# Install nvidia-container-toolkit
echo -e "* ${BLUE}Setting up NVIDIA Container package repository${NOCOLOR}"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
cmd "sudo apt update"
cmd "sudo apt install -y nvidia-container-toolkit"
cmd "sudo nvidia-ctk runtime configure --runtime=docker"
cmd "sudo systemctl restart docker"

# Enable docker access for the current user
cmd "sudo gpasswd -a $USER docker"

echo -e "${YELLOW}Done!${NOCOLOR} 🍺"

# Check if we need to restart
if ! id -nG "$USER" | grep -qw "docker"; then
  echo -e "${RED}Please restart${NOCOLOR}"
fi
