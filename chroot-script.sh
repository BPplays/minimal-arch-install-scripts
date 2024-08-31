#!/bin/bash

set -euo pipefail

mount -a

cat <<EOF >>/etc/resolv.conf
nameserver fd0e:a882:618c::20:0
nameserver fd0e:a882:618c::20:1
nameserver fd0e:a882:618c::20:2
nameserver fd0e:a882:618c::
nameserver 2601:204:4100:1db0:250:56ff:fe3e:d7b9
nameserver 2601:204:4100:1db0:250:56ff:fe3c:e6c4
nameserver 10.0.20.0
nameserver 10.0.20.2
nameserver 10.0.20.1
nameserver 2620:fe::fe
nameserver 2620:fe::9
nameserver 9.9.9.9
EOF
pacman -Syu --noconfirm

pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\nUsage = Sync Search" | tee -a /etc/pacman.conf

pacman -Syu  --noconfirm chaotic-aur/crudini amd-ucode intel-ucode sudo rclone

crudini --set /etc/pacman.conf options ParallelDownloads 256

set +euo pipefail
pacman -Syu --noconfirm chaotic-aur/yay chaotic-aur/powerpill
TMPDIR=$(mktemp -d)
git clone https://aur.archlinux.org/freeipa.git $TMPDIR
gpg --import $TMPDIR/keys/pgp/*asc
rm -fr $TMPDIR
# yay -Sua --sudoloop --noconfirm --aur freeipa-client



# pacman -Syu  --noconfirm freeipa-client freeipa-client-common freeipa-common dos2unix
pacman -Syu  --noconfirm dos2unix fish zsh
set -euo pipefail

# set settings related to locale
sed -i -e 's|#ja_JP UTF-8|ja_JP UTF-8|' -e 's|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# set the time zone
ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime
hwclock --systohc

# set hostname
echo "${HOSTNAME}" >/etc/hostname

# configure hosts file
cat <<EOF >>/etc/hosts
::1          localhost
::1          ${HOSTNAME}
127.0.0.1    localhost
127.0.1.1    ${HOSTNAME}
EOF

# # set root user password
# set +euo pipefail
# while true; do
# 	passwd
#
# 	# Break the loop if the command succeeds (exit code 0)
# 	if [[ $? -eq 0 ]]; then
# 		break
# 	fi
#
# 	# echo "Command failed. Retrying..."
# 	# sleep 2  # Optional: wait for 2 seconds before retrying
# done
# set -euo pipefail

echo "root:$ROOT_PASS" | sudo chpasswd

# configure mkinitcpio
# sed -i '/^HOOKS/s/\(block \)\(.*filesystems\)/\1encrypt lvm2 \2/' /etc/mkinitcpio.conf


# generate initramfs for linux and linux-lts
set +euo pipefail
# mkinitcpio -P
mkinitcpio -p linux
echo "mkinitcpio -p linux"
mkinitcpio -p linux-lts
echo "mkinitcpio -p linux-lts"
set -euo pipefail

# install and configure refind
refind-install
echo "refind installed"

# enable NetworkManager systemd service


iw reg set US

systemctl enable NetworkManager


set +euo pipefail
# Define the username and home directory
USERNAME="local_admin"
HOME_DIR="/local-home/$USERNAME"
mkdir -p "/local-home/"

# Create the user with the specified home directory and add them to the 'wheel' group
if id "$USERNAME" &>/dev/null; then
	echo "User '$USERNAME' already exists. Skipping creation."
else
	echo "Creating user '$USERNAME' with home directory '$HOME_DIR'..."
	sudo useradd -m -d "$HOME_DIR" -G wheel "$USERNAME"
fi

echo "$USERNAME:$LOCAL_ADMIN_PASS" | sudo chpasswd

# Verify if the user was added to the wheel group
if id "$USERNAME" | grep -q "wheel"; then
	echo "User '$USERNAME' successfully added to the 'wheel' group."
else
	echo "Failed to add user '$USERNAME' to the 'wheel' group."
fi

echo "User '$USERNAME' is now a local admin with a home directory at '$HOME_DIR'."
cat <<EOF >/etc/sudoers
# User privilege specification
root    ALL=(ALL:ALL) ALL

# Allow members of group sudo to execute any command
%sudo   ALL=(ALL:ALL) ALL
%sudoers   ALL=(ALL:ALL) ALL
%wheel   ALL=(ALL:ALL) ALL

# See sudoers(5) for more information on "@include" directives:

@includedir /etc/sudoers.d
EOF
set -euo pipefail




# set +euo pipefail
# while true; do
# 	# Ask the user if they want to cancel the FreeIPA installation
# 	read -p "Do you want to install FreeIPA client using ipa-client-install? (y/N): " install_ipa
#
# 	install_ipa=${install_ipa:-N}  # Default to 'Y' if no input
# 	if [[ "$install_ipa" =~ ^[Nn]$ ]]; then
# 		echo "Installation of FreeIPA client was cancelled."
# 		break
# 	fi
#
# 	# Ask the user if they want to use --mkhomedir
# 	read -p "Do you want to use the --mkhomedir option? (y/n): " use_mkhomedir
# 	if [[ "$use_mkhomedir" =~ ^[Yy]$ ]]; then
# 		mkhomedir="--mkhomedir"
# 	else
# 		mkhomedir=""
# 	fi
#
# 	# Ask the user if they want to use --force-join
# 	read -p "Do you want to use the --force-join option? (y/n): " use_forcejoin
# 	if [[ "$use_forcejoin" =~ ^[Yy]$ ]]; then
# 		forcejoin="--force-join"
# 	else
# 		forcejoin=""
# 	fi
#
# 	# Construct the command with selected options
# 	cmd="ipa-client-install $mkhomedir $forcejoin"
# 	echo "Running command: $cmd"
#
# 	# Execute the command
# 	$cmd
#
# 	# Check the exit status of the command
# 	if [[ $? -eq 0 ]]; then
# 		echo "FreeIPA client installation was successful."
# 		break
# 	else
# 		echo "FreeIPA client installation failed. Retrying..."
# 	fi
# done
# set -euo pipefail



