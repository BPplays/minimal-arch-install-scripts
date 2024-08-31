#!/bin/bash

# # List of AUR packages to install
# AUR_PACKAGES=(
#   "freeipa-client"
# )

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
	echo "Please run as root"
	exit 1
fi

# Update system and install necessary dependencies for building AUR packages
pacman -Syu --noconfirm
pacman -S --needed --noconfirm base-devel git rclone

# Create a temporary directory for installing yay
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Clone yay repository
git clone https://aur.archlinux.org/yay.git
cd yay

# Build and install yay
makepkg -si --noconfirm

# Clean up
cd /
rm -rf "$TMPDIR"

# # Use yay to install AUR packages
# for package in "${AUR_PACKAGES[@]}"; do
# 	yay -S --noconfirm "$package"
# done

# echo "All specified AUR packages have been installed."

# End of script
