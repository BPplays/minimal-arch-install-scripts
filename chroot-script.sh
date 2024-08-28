#!/bin/bash

set -euo pipefail

mount -a
pacman -Syu --noconfirm

pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | tee -a /etc/pacman.conf

pacman -Syu  --noconfirm crudini

crudini --set /etc/pacman.conf options ParallelDownloads 256
pacman -Syu  --noconfirm lvm2

set +euo pipefail
pacman -Syu  --noconfirm freeipa-client freeipa-client-common freeipa-common dos2unix
pacman -Syu  --noconfirm sudo
set -euo pipefail

# set settings related to locale
sed -i -e 's|#ja_JP UTF-8|ja_JP UTF-8|' -e 's|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# set the time zone
echo -n "Enter Time Zone: "
read -r TIME_ZONE
ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime
hwclock --systohc

# set hostname
echo -n "Enter hostname: "
read -r HOSTNAME
echo "${HOSTNAME}" >/etc/hostname

# configure hosts file
cat <<EOF >>/etc/hosts
::1          localhost
::1          ${HOSTNAME}
127.0.0.1    localhost
127.0.1.1    ${HOSTNAME}
EOF

# set root user password
passwd



# configure mkinitcpio
# sed -i '/^HOOKS/s/\(block \)\(.*filesystems\)/\1encrypt lvm2 \2/' /etc/mkinitcpio.conf


# generate initramfs for linux and linux-lts
set +euo pipefail
mkinitcpio -P
# mkinitcpio -p linux
# echo "mkinitcpio -p linux"
# mkinitcpio -p linux-lts
# echo "mkinitcpio -p linux-lts"
set -euo pipefail

# install and configure refind
refind-install
echo "refind installed"

# enable NetworkManager systemd service
systemctl enable NetworkManager
