# Technically overwritten by the PS1 from config
export PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[35m\]\$(parse_git_branch)\[\033[00m\]\$ "
export TERM=xterm-256color
alias grep="grep --color=auto"
alias ls="ls --color=auto"

echo -e "\e[1;32m"
cat<<VR

 ______   _______          
(  __  \ (  ____ \|\     /|
| (  \  )| (    \/| )   ( |
| |   ) || (__    | |   | |
| |   | ||  __)   ( (   ) )
| |   ) || (       \ \_/ / 
| (__/  )| (____/\  \   /  
(______/ (_______/   \_/   
                           

VR
echo -e "\e[0;32m"
echo "           Welcome to the dev docker"
echo -e "\e[0;33m"

if [[ $EUID -eq 0 ]]; then
  cat <<WARN
WARNING: You are running this container as root, which can cause new files in
mounted volumes to be created as the root user on your host machine.

To avoid this, run the container by specifying your user's userid:

$ docker run -u \$(id -u):\$(id -g) args...
WARN
fi

# Turn off colors
echo -e "\e[m"

# export PATH=$PATH  # Update the PATH to include the user's bin directory