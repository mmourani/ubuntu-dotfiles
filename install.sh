#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Maroun Mourani
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib_sh/echos.sh

bot "Hi! I'm going to install tooling and tweak your system settings. Here I go..."


# Ask for the administrator password upfront
if ! sudo grep -q "%wheel       ALL=(ALL) NOPASSWD: ALL #atomantic/dotfiles" "/etc/sudoers"; then

  # Ask for the administrator password upfront
  bot "I need you to enter your sudo password so I can install some things:"
  sudo -v

  # Keep-alive: update existing sudo time stamp until the script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  bot "Do you want me to setup this machine to allow you to run sudo without a password?\nPlease read here to see what I am doing:\nhttp://wiki.summercode.com/sudo_without_a_password_in_mac_os_x \n"

  read -r -p "Make sudo passwordless? [y|N] " response

  if [[ $response =~ (yes|y|Y) ]];then
      sudo cp /etc/sudoers /etc/sudoers.back
      echo '%wheel      ALL=(ALL) NOPASSWD: ALL #atomantic/dotfiles' | sudo tee -a /etc/sudoers > /dev/null
      sudo dscl . append /Groups/wheel GroupMembership $(whoami)
      bot "You can now run sudo commands without password!"
  fi
fi

#==================================== Imports ===============================================
# Import base
. base/import.sh

# Import Sytem
. system/import.sh


# Presentation function and options
welcome(){

clear
echo -e "
${txtblu}
===================================

        AutoInstall SH
Created by Maroun Mourani

===================================

${txtrst}Options:

${Red}########## System${txtrst}
 "
for file in $(ls ./system)
do
    if [ $file != import.sh ]
    then
        echo $file
    fi

done;

echo -e "


e - Exit

==================================

Enter an option:
"
    read program

case $program in

    # Performs the function with the name of the variable passed
    e) clear; exit;;
    $program) $program; ready;;
    *) welcome;;

esac
}

welcome
