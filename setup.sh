#!/usr/bin/env bash

###############################
## Ask for admin credentials ##
###############################
sudo -v

###############################
## Update and upgrade system ##
###############################
sudo apt update
sudo apt upgrade -y

##################
## Install apps ##
##################
apps=(
    calibre
    curl
    entr
    ffmpeg
    git
    graphviz
    grub-customizer
    latexmk
    latte-dock
    libnotify-bin
    libreoffice
    lm-sensors
    postgresql
    powertop
    python3-pip
    rename
    shellcheck
    silversearcher-ag
    texlive-full
    tlp
    translate-shell
    tree
    ufw
    zsh
    zsh-syntax-highlighting
)

sudo apt install -y "${apps[@]}" || true

###################
## Install Guake ##
###################
git clone https://github.com/Guake/guake.git
cd guake || return
./scripts/bootstrap-dev-debian.sh run make
make
sudo make install
cd .. || return
rm -rf guake

#############################
## Add obs ppa and install ##
#############################
sudo add-apt-repository ppa:obsproject/obs-studio
sudo apt update
sudo apt install -y obs-studio

##################################
## Add kdenlive ppa and install ##
##################################
sudo add-apt-repository ppa:kdenlive/kdenlive-stable
sudo apt update
sudo apt install -y kdenlive

####################
## Install pandoc ##
####################

# Create the url
url_part1="https://github.com"
tempvar=$(curl "$url_part1/jgm/pandoc/releases")

# Get the first link with a .deb file ending, it's the latest pandoc linux release
url_part2=$(echo "$tempvar" | sed -n '/amd64.deb/p' | awk '/<a href/{print $2;exit;}' | sed 's/href=//; s/\"//g')

# Download pandoc
wget "$url_part1$url_part2"

# Install pandoc
package=$(ls ./*.deb)
sudo dpkg -i "$package"
sudo apt install -f

# Delete .deb file
rm "$package"

#######################
## Install Oh-My-zsh ##
#######################
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended

#######################################
## Install libinput-gestures ##
#######################################

# Check if it's a notebook
if [ -d "/sys/class/power_supply" ]; then
    # Install libinput-gestures for swiping gestures
    if ! type "libinput-gestures" &>/dev/null; then
        sudo gpasswd -a "$USER" input
        sudo apt install -y xdotool wmctrl libinput-tools

        cd ~ || return
        git clone https://github.com/bulletmark/libinput-gestures.git
        cd libinput-gestures || return
        sudo make install
        cd .. || return
        rm -rf libinput-gestures

        libinput-gestures-setup autostart
        libinput-gestures-setup start
    fi
fi

#####################
## Install VS Code ##
#####################

# Check if code is installed
if ! type "code" &>/dev/null; then
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"

    sudo apt install apt-transport-https
    sudo apt update
    sudo apt install -y code
fi

# Install VS Code extensions
if type "code" &>/dev/null; then
    extensions=(
        Angular.ng-template
        DavidAnson.vscode-markdownlint
        EFanZh.graphviz-preview
        James-Yu.latex-workshop
        PKief.material-icon-theme
        Tyriar.sort-lines
        VisualStudioExptTeam.vscodeintellicode
        albert.TabOut
        dbaeumer.vscode-eslint
        eamodio.gitlens
        foxundermoon.shell-format
        geeklearningio.graphviz-markdown-preview
        humao.rest-client
        jmrog.vscode-nuget-package-manager
        joaompinto.vscode-graphviz
        ms-dotnettools.csharp
        ms-mssql.sqlops-debug
        ms-python.python
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode.cpptools
        ms-vscode.vscode-typescript-tslint-plugin
        ms-vsliveshare.vsliveshare
        redhat.java
        ritwickdey.LiveServer
        streetsidesoftware.code-spell-checker
        streetsidesoftware.code-spell-checker-german
        sumneko.lua
        timonwong.shellcheck
        vmsynkov.colonize
        vscjava.vscode-java-debug
        yycalm.linecount
        yzhang.markdown-all-in-one
        zhuangtongfa.material-theme
    )
    for extension in ${extensions[*]}; do
        code --install-extension "$extension"
    done
fi

##########################################
## Install youtube-dl, pylint, autopep8 ##
##########################################

# Check if pip3 is installed
if type "pip3" &>/dev/null; then
    pip3 install youtube-dl pylint autopep8 pandocfilters jupyter pandas eyed3

    echo '--output "~/Downloads/%(title)s.%(ext)s"' >"/home/$USER/.config/youtube-dl.conf"
fi

###########################
## Create symbolic links ##
###########################

# git
gitconfig="$HOME/dev/dotfiles/git/.gitconfig"
gitconfig_location="$HOME/.gitconfig"
ln -sfn "$gitconfig" "$gitconfig_location"

# guake
guake="$HOME/dev/dotfiles/guake/user"
guake_location="$HOME/.config/dconf/user"
ln -sfn "$guake" "$guake_location"

# nano
nanorc="$HOME/dev/dotfiles/nano/.nanorc"
nanorc_location="$HOME/.nanorc"
ln -sfn "$nanorc" "$nanorc_location"

# VS Code
vscode_settings="$HOME/dev/dotfiles/vscode/settings.json"
vscode_settings_location="$HOME/.config/Code/User/settings.json"
ln -sfn "$vscode_settings" "$vscode_settings_location"

vscode_keybindings="$HOME/dev/dotfiles/vscode/keybindings.json"
vscode_keybindings_location="$HOME/.config/Code/User/keybindings.json"
ln -sfn "$vscode_keybindings" "$vscode_keybindings_location"

# zsh
zshrc="$HOME/dev/dotfiles/zsh/.zshrc"
zshrc_location="$HOME/.zshrc"
ln -sfn "$zshrc" "$zshrc_location"

theme="$HOME/dev/dotfiles/zsh/nidzo.zsh-theme"
theme_location="$HOME/.oh-my-zsh/themes/nidzo.zsh-theme"
ln -sfn "$theme" "$theme_location"

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Dotfiles dir with git
mkdir "$HOME/dev/temp"
cd "$HOME/dev" || return
git clone https://github.com/nidzov/dotfiles.git "$HOME/dev/temp"
mv "$HOME/dev/temp/.git" "$HOME/dev/dotfiles"
rm -rf "$HOME/dev/temp"

# Change remote url of dotfiles
cd "$HOME/dev/dotfiles" || return
git remote set-url origin git@github.com:Nidzo-Vidic/dotfiles.git

#######################
## Disable Services ##
#######################
sudo systemctl disable NetworkManager-wait-online.service # Not needed service, decreases boot time
sudo systemctl mask NetworkManager-wait-online.service    # Not needed service, decreases boot time
sudo systemctl disable bluetooth.service
sudo systemctl disable postgresql.service
