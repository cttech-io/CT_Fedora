#!/bin/bash
### This is a post install script for Fedora that tweaks some settings, install packages, enables proper Flatpak support and can install NVIDIA drivers ###
### Author: Charlie Taylor ###

#Check if script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user to run this script." 2>&1
  exit 1
fi

#Edit DNF Repo settings
echo max_parallel_downloads=10 >> /etc/dnf/dnf.conf
echo fastestmirror=True >> /etc/dnf/dnf.conf

#Update Repos & Packages
dnf check-upgrade
sudo dnf upgrade -y

#Add RPM Fusion Repo
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

#Update Repos & Packages again
dnf check-upgrade
sudo dnf upgrade -y

#Install Base Packages
sudo dnf install @base-x gnome-shell gnome-terminal nautilus -y
sudo dnf group install "Hardware Support" -y

#Install userland packages
firefox flatpak gnome-terminal-nautilus xdg-user-dirs xdg-user-dirs-gtk ffmpegthumbnailer gnome-system-monitor htop-y

#Set Graphical boot as default 
sudo systemctl set-default graphical.target

#Setup Terminal stuff (Oh my ZSH, Powerlevel10k theme & tldr)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -P /usr/share/fonts
fc-cache -vf
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
tldr --update

#Enable Flathub Repo 
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

#Install Flatpaks
flatpak install app/com.bitwarden.desktop/x86_64/stable -y
flatpak install flathub com.visualstudio.code -y
flatpak install app/com.raggesilver.BlackBox/x86_64/stable -y
flatpak install flathub com.mattjakeman.ExtensionManager -y
flatpak install flathub org.remmina.Remmina -y
flatpak install flathub org.chromium.Chromium -y
flatpak install flathub com.spotify.Client -y

#Disable un-needed services
sudo systemctl disable cups NetworkManager-wait-online.service

#Set SELinux to Permissive mode
sed -i s/^SELINUX=.*$/SELINUX=permissive/ /etc/selinux/config
setenforce 0

#Check for and install firmware updates
sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates
sudo fwupdmgr update

#Install NVIDIA Drivers
read -p "Would you like to install the proprietary NVIDIA Drivers? (Yes/No)" choice
if [[ "$choice" =~ ^[Yy] ]]
	then
		echo "Okay, installing NVIDIA drivers."
		sudo dnf install akmod-nvidia -y && sudo dnf install xorg-x11-drv-nvidia-cuda
	else
		echo "Okay, Not installing NVIDIA drivers.
		"
fi

#Setup complete. Ask user if they want to reboot system now
read -p "Setup of this system is complete. Reboot is recommended. Would you like to do this now?" reboot_choice
if [[ "$reboot_choice" =~ ^[Yy] ]]
	then
		echo "Rebooting in 10 seconds"
		sleep 10
		sudo reboot now
	else
		echo "Exiting Setup"
		sleep 1
fi

exit