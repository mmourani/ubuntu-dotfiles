#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Maroun Mourani
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib_sh/echos.sh

bot "Hi! I'm going to install tooling and tweak your system settings. Here I go..."

sudo -i

# /etc/hosts
read -r -p "Overwrite /etc/hosts with the ad-blocking hosts file from someonewhocares.org? (from ./configs/hosts file) [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    action "cp /etc/hosts /etc/hosts.backup"
    sudo cp /etc/hosts /etc/hosts.backup
    ok
    action "cp ./configs/hosts /etc/hosts"
    sudo cp ./configs/hosts /etc/hosts
    ok
    bot "Your /etc/hosts file has been updated. Last version is saved in /etc/hosts.backup"
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
