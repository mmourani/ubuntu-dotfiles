#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Maroun Mourani
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib_sh/echos.sh

#==================================== Imports ===============================================
# Import base
. base/import.sh

# Import Sytem
. system/import.sh

bot "Hi! I'm going to install tooling and tweak your system settings. Here I go..."

# go into sudo mode...
# Ask for the administrator password upfront
action "entering sudo mode..."
sudo -v
ok
bot "sudo mode confirmed"

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

grep 'user = GITHUBUSER' ./homedir/.gitconfig > /dev/null 2>&1
if [[ $? = 0 ]]; then

    read -r -p "What is your github.com username? " githubuser
    if [[ ! $githubuser ]];then
      error "you must provide a username to configure .gitconfig"
      exit 1
    fi

    read -r -p "What is your first name? " firstname
    if [[ ! $firstname ]];then
      error "you must provide a first name to configure .gitconfig"
      exit 1
    fi

    read -r -p "What is your last name? " lastname
    if [[ ! $lastname ]];then
      error "you must provide a last name to configure .gitconfig"
      exit 1
    fi
    fullname="$firstname $lastname"
    bot "Great $fullname, "

    read -r -p "What is your email? " email
    if [[ ! $email ]];then
      error "you must provide an email to configure .gitconfig"
      exit 1
    fi
    running "replacing items in .gitconfig with your info ($COL_YELLOW$fullname, $email, $githubuser$COL_RESET)"

  # test if gnu-sed or MacOS sed

  sed -i "s/GITHUBFULLNAME/$firstname $lastname/" ./homedir/.gitconfig > /dev/null 2>&1 | true
  if [[ ${PIPESTATUS[0]} != 0 ]]; then
    echo
    running "looks like you are using MacOS sed rather than gnu-sed, accommodating"
    sed -i '' "s/GITHUBFULLNAME/$firstname $lastname/" ./homedir/.gitconfig;
    sed -i '' 's/GITHUBEMAIL/'$email'/' ./homedir/.gitconfig;
    sed -i '' 's/GITHUBUSER/'$githubuser'/' ./homedir/.gitconfig;
    ok
  else
    echo
    bot "looks like you are already using gnu-sed. woot!"
    sed -i 's/GITHUBEMAIL/'$email'/' ./homedir/.gitconfig;
    sed -i 's/GITHUBUSER/'$githubuser'/' ./homedir/.gitconfig;
  fi
fi

  ok
  # Make sure we’re updating the system 
  action "updating ubuntu"
  update
  ok

  # install fontconfig if not already done
  action "installing fontconfig"
  sudo apt-get --yes install fontconfig
  ok

  # install zsh if not already done
  action "installing zsh"
  sudo apt-get --yes install zsh
  ok

  # install ruby if not already done
  action "installing ruby"
  sudo apt-get --yes install ruby-full
  ok

  # install cmake as it is needed to compile vim
  action "installing cmake"
  sudo apt-get --yes install cmake
  ok

# install fortune 
  action "installing fortune"
  sudo apt-get --yes install fortune
  ok

  # set zsh as user login shell 
  action "setting zsh as default login shell"
  sudo chsh -s "$(command -v zsh)" "${USER}"
  ok

  # install docker-ce
  action "removing older version of docker CE"
  sudo apt-get --yes remove docker docker-engine docker.io
  action "install docker repository"
  sudo apt-get --yes update
  sudo apt-get --yes install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-commons
  action "Add Docker’s official GPG key"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo apt-key fingerprint 0EBFCD88
  action "Use docker stable repo"
  sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
  action "install docker CE"
  sudo apt-get --yes update
  sudo apt-get --yes install docker-ce
  sudo docker run hello-world
  ok

  # download and install docker compose
  action "install docker compose"
  sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  ok

  # install nvm 
  action "install nvm"
  sudo apt-get --yes update
  sudo apt-get --yes install build-essential libss1-dev
  curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh -o install_nvm.sh
  bash install_nvm.sh
  nvm install 8.9.4
  ok

  # copy powerlevel9k theme to oh-my-zsh
  action "installing powerlevel9K theme to oh-my-zsh"
  if [[ ! -d "./oh-my-zsh/custom/themes/powerlevel9k" ]]; then
  git clone https://github.com/bhilburn/powerlevel9k.git oh-my-zsh/custom/themes/powerlevel9k
  fi

  # copy zsh-syntax-highlighting plugin to oh-my-zsh
  action "installing zsh-syntax-highlighting plugin to oh-my-zsh"
    if [[ ! -d "./oh-my-zsh/plugins/zsh-syntax-highlighting" ]]; then
  git clone git@github.com:zsh-users/zsh-syntax-highlighting.git oh-my-zsh/plugins/zsh-syntax-highlighting
  fi

  # copy zsh-autosuggestions plugin to oh-my-zsh
  action "installing zsh-autosuggestions plugin to oh-my-zsh"
    if [[ ! -d "./oh-my-zsh/plugins/zsh-autosuggestions" ]]; then
  git clone git@github.com:zsh-users/zsh-autosuggestions.git oh-my-zsh/plugins/zsh-autosuggestions
  fi


  bot "creating symlinks for project dotfiles..."
  pushd homedir > /dev/null 2>&1
  now=$(date +"%Y.%m.%d.%H.%M.%S")

    for file in .*; do
      if [[ $file == "." || $file == ".." ]]; then
        continue
      fi
      running "~/$file"
      # if the file exists:
      if [[ -e ~/$file ]]; then
          mkdir -p ~/.dotfiles_backup/$now
          mv ~/$file ~/.dotfiles_backup/$now/$file
          echo "backup saved as ~/.dotfiles_backup/$now/$file"
      fi
      # symlink might still exist
      unlink ~/$file > /dev/null 2>&1
      # create the link
      ln -s ~/.dotfiles/homedir/$file ~/$file
      echo -en '\tlinked';ok
    done


  popd > /dev/null 2>&1


  bot "Installing vim plugins"
  # cmake is required to compile vim bundle YouCompleteMe
  #vim +PluginInstall +qall > /dev/null 2>&1
  vim +PluginInstall +qall 

  bot "installing fonts"
  ./fonts/install.sh
  sudo apt-get --yes install fonts-font-awesome
  sudo apt-get install fonts-powerline

  # installing font-awesome-terminal-fonts
  action "installing font-awesome-terminal-fonts"
  font-awesome-terminal-fonts

  # installing Hack fonts
  action "installing Hack fonts"
  Hack-fonts


# install hyperledger
  action "install hyperledger"
  curl -O https://hyperledger.github.io/composer/latest/prereqs-ubuntu.sh
  chmod u+x prereqs-ubuntu.sh
  ./prereqs-ubuntu.sh
  npm install -g composer-cli@0.20
  npm install -g composer-rest-server@0.20
  npm install -g generator-hyperledger-composer@0.20
  npm install -g yo
  npm install -g composer-playground@0.20
  mkdir ~/fabric-dev-servers && cd ~/fabric-dev-servers
  curl -O https://raw.githubusercontent.com/hyperledger/composer-tools/master/packages/fabric-dev-servers/fabric-dev-servers.tar.gz
  tar -xvf fabric-dev-servers.tar.gz
  cd ~/fabric-dev-servers
  export FABRIC_VERSION=hlfv12
  ./downloadFabric.sh
  ok
  

