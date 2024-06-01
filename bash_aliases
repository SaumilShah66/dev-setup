#!/usr/bin/env bash
USER_HOME=$(eval echo ~${SUDO_USER})

# Git branch
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Ask (y/n) ?
prompt_continue() {
  while true; do
    read -r -n 1 -p "${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
      [yY]) echo -e "\n"; return 0 ;;
      *) echo -e "\n"; exit ;;
    esac
  done
}

# Check if apt package is installed and install if not
check_apt_install() {
  # Create an array of packages to install
  PKGS=()
  for PKG in "$@"; do
    PKG_OK=$(dpkg --get-selections | grep -w $PKG | awk '{print $1}')
    if [[ -z "$PKG_OK" ]]; then
      PKGS+=($PKG)
    fi
  done
  # if there is something in the array, update and install
  if [[ ${#PKGS[@]} -gt 0 ]]; then
    echo "Installing ${PKGS[@]}"
    sudo apt -qq update &> /dev/null
    sudo apt -qq install -y ${PKGS[@]} &> /dev/null
  fi
}

# Install pip package
check_pip_install() {
  for PKG in "$@"; do
    PKG_OK=$(python3 -m pip list --disable-pip-version-check | grep $PKG | awk '{print $1}')
    if [[ -z "$PKG_OK" ]]; then
      echo "Installing $PKG"
      python3 -m pip install $PKG --quiet
    fi
  done
}

get_ps1() {
  echo "\033[01;32m$USER@$(uname -n)\033[00m:\033[01;34m${PWD/#$HOME/'~'}\033[35m$(parse_git_branch)\033[0m$"
}

if [ -f /.dockerenv ]; then
  if [ -f /vdev-tag ]; then
    ENV_TAG="vdev"
  else
    ENV_TAG="run"
  fi
else
  ENV_TAG="host"
fi

export PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;90m\]($ENV_TAG)\[\033[00m\]:\[\033[01;34m\]\w\[\033[35m\]\$(parse_git_branch)\[\033[00m\]\$ "

# Random
alias e='exit'
alias c='clear'

# git
alias gs='git status'
alias gb='git branch'
alias gp='git pull --rebase'
alias gc='git commit'
alias ga='git add -u'
alias gf='git fetch'
alias gcp='git cherry-pick'
alias gac='git commit -a -m'
alias gcm='git checkout master'
alias gcb='git checkout -b'
alias gmom='git merge origin master'
alias gpob='git push origin $(parse_git_branch)'
alias gpom='git pull origin master'
alias gitssh='eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519'

# Use double quotes here so we expand the env var on the alias
ARCH="$(uname -p)"

# more shortcuts
alias cd..="cd .."
alias ..="cd .."
alias up="cd .."
alias up2="cd ../.."
alias up3="cd ../../.."
alias up4="cd ../../../.."
alias up5="cd ../../../../.."
