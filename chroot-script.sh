#!/bin/bash

set -euo pipefail

mount -a
pacman -Syu --noconfirm

pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | tee -a /etc/pacman.conf

pacman -Syu  --noconfirm crudini amd-ucode intel-ucode sudo

crudini --set /etc/pacman.conf options ParallelDownloads 256

set +euo pipefail
pacman -Syu  --noconfirm freeipa-client freeipa-client-common freeipa-common dos2unix
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
while true; do
	# Ask the user if they want to cancel the FreeIPA installation
	read -p "Do you want to install FreeIPA client using ipa-client-install? (y to proceed/n to cancel): " install_ipa
	if [[ "$install_ipa" =~ ^[Nn]$ ]]; then
		echo "Installation of FreeIPA client was cancelled."
		break
	fi

	# Ask the user if they want to use --mkhomedir
	read -p "Do you want to use the --mkhomedir option? (y/n): " use_mkhomedir
	if [[ "$use_mkhomedir" =~ ^[Yy]$ ]]; then
		mkhomedir="--mkhomedir"
	else
		mkhomedir=""
	fi

	# Ask the user if they want to use --force-join
	read -p "Do you want to use the --force-join option? (y/n): " use_forcejoin
	if [[ "$use_forcejoin" =~ ^[Yy]$ ]]; then
		forcejoin="--force-join"
	else
		forcejoin=""
	fi

	# Construct the command with selected options
	cmd="ipa-client-install $mkhomedir $forcejoin"
	echo "Running command: $cmd"

	# Execute the command
	$cmd

	# Check the exit status of the command
	if [[ $? -eq 0 ]]; then
		echo "FreeIPA client installation was successful."
		break
	else
		echo "FreeIPA client installation failed. Retrying..."
	fi
done
set -euo pipefail



