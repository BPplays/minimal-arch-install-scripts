#!/bin/bash

set -euo pipefail

# check if boot type is UEFI
ls /sys/firmware/efi/efivars || { echo "Boot Type Is Not UEFI!; "exit 1; }

# check if internet connection exists
ping -q -c 1 archlinux.org >/dev/null || { echo "No Internet Connection!; "exit 1; }

# update system clock
timedatectl set-ntp true

# read the block device path you want to install Arch on
echo -n "Enter the block device path you want to install Arch on: "
read -r BLOCK_DEVICE

# ask if the user wants default partitioning or wants to do partitioning manually with cfdisk?
echo -n "Do you want to do partitioning manually with cfdisk? [y/N]: "
read -r PARTITIONING

echo -n "main partition size GB: "
read -r arch_size_gb

# giga___10_power_9=1000000000
gb_to_gib=0.9313225746

echo -n "Enter Time Zone: "
read -r TIME_ZONE_t
export TIME_ZONE="$TIME_ZONE_t"

echo -n "Enter hostname: "
read -r HOSTNAME_t
export HOSTNAME="$HOSTNAME_t"

while true; do
    # Prompt for the password
    read -s -p "Enter root password: " password
    echo

    # Prompt for the confirmation
    read -s -p "Confirm password: " confirm_password
    echo

    # Check if passwords match
    if [ "$password" == "$confirm_password" ]; then
        # Export the variable
        export ROOT_PASS="$password"

        break
    else
        echo "Passwords do not match. Please try again."
    fi
done


arch_size_GIB=$(echo "$arch_size_gb * $gb_to_gib" | bc)

# if the user wants to create [one] LUKS partition manually with cfdisk (in case there are already other OS's installed)
if [ "${PARTITIONING}" == "y" ]; then
    # partition the block device with cfdisk
    cfdisk "${BLOCK_DEVICE}"
else
    sgdisk --clear \
      -n 1:2048:+1907M -t 1:EF00 -c 1:"Arch Linux-EFI System" \
      -n 2:0:+1907M -t 2:ea00 -c 2:"Arch Linux-Boot" \
      -n 3:0:+${arch_size_GIB}G -t 3:8309 -c 3:"Arch Linux" \
      "${BLOCK_DEVICE}"

    # format EFI partition
    mkfs.fat -F32 "${BLOCK_DEVICE}p1"
    mkfs.ext4 -m 2 "${BLOCK_DEVICE}p2"
fi

# show partitions
lsblk

# read the boot/efi partition path
echo -n "Enter the efi partition path: "
read -r EFI_PARTITION

echo -n "Enter the boot partition path: "
read -r BOOT_PARTITION

# read the LUKS partition path
echo -n "Enter the LUKS partition path: "
read -r NEW_PARTITION

# create a LUKS partiton
# Turn off 'set -euo pipefail'
set +euo pipefail

# Define your command in a loop
while true; do

    while true; do
        # Prompt for the password
        read -s -p "Enter luks encryption password: " password
        echo

        # Prompt for the confirmation
        read -s -p "Confirm password: " confirm_password
        echo

        # Check if passwords match
        if [ "$password" == "$confirm_password" ]; then
            # Export the variable
            export LUKS_PASS="$password"

            break
        else
            echo "Passwords do not match. Please try again."
        fi
    done




    echo -n "$LUKS_PASS" | cryptsetup luksFormat "${NEW_PARTITION}" --key-file=- --cipher aes-xts-plain64 --hash sha256 --iter-time 2000 --key-size 512

    # Break the loop if the command succeeds (exit code 0)
    if [[ $? -eq 0 ]]; then
        break
    fi

    # echo "Command failed. Retrying..."
    # sleep 2  # Optional: wait for 2 seconds before retrying
done

# Re-enable 'set -euo pipefail'
set -euo pipefail

# open the LUKS partition

set +euo pipefail
while true; do
    echo -n "$LUKS_PASS" | cryptsetup open "${NEW_PARTITION}" cryptlvm --key-file=-

    # Break the loop if the command succeeds (exit code 0)
    if [[ $? -eq 0 ]]; then
        break
    fi

    # echo "Command failed. Retrying..."
    # sleep 2  # Optional: wait for 2 seconds before retrying
done
set -euo pipefail

# create physical volume on the LUKS partition
pvcreate /dev/mapper/cryptlvm

# create logical volume group on the physical volume
vgcreate vg1 /dev/mapper/cryptlvm


# Replace 'your_vg_name' with the actual name of your volume group
VG_NAME="vg1"

# Get the total size of the volume group in bytes
total_size_bytes=$(vgs --noheadings --nosuffix --units B -o vg_size $VG_NAME | tr -d ' ')

# Calculate 2% of the total size in bytes
size_2_percent_bytes=$((total_size_bytes * 2 / 100))

# Convert 5GB to bytes (1 GB = 1,000,000,000 bytes)
min_size_bytes=$((5 * 1000000000))

# Determine the size to use (max of 2% of total size or 5GB)
lv_size_bytes=$((size_2_percent_bytes > min_size_bytes ? size_2_percent_bytes : min_size_bytes))

# Convert the size to MB (LVM command requires sizes in MB)
lv_size_mb=$((lv_size_bytes / 1000000))

# Create the logical volume with the calculated size
lvcreate -L ${lv_size_mb}M -n var_log $VG_NAME
lvcreate -L ${lv_size_mb}M -n var_cache $VG_NAME
lvcreate -L ${lv_size_mb}M -n var_tmp $VG_NAME
lvcreate -L ${lv_size_mb}M -n tmp $VG_NAME

# create logical volume named home on the volume group with the rest of the space
lvcreate -l 90%FREE vg1 -n root


mkfs.btrfs --csum XXHASH /dev/vg1/root
mkfs.btrfs --csum XXHASH /dev/vg1/var_log
mkfs.btrfs --csum XXHASH /dev/vg1/var_cache
mkfs.btrfs --csum XXHASH /dev/vg1/var_tmp

mkfs.ext4 -m 2 /dev/vg1/tmp
tune2fs -O ^has_journal /dev/vg1/tmp

# mount the root partition
mount /dev/vg1/root /mnt


mkdir -p /mnt/var/log
mkdir -p /mnt/var/cache
mkdir -p /mnt/tmp
mkdir -p /mnt/var/tmp

mount /dev/vg1/var_log /mnt/var/log
mount /dev/vg1/var_cache /mnt/var/cache
mount /dev/vg1/tmp /mnt/tmp
mount /dev/vg1/var_tmp /mnt/var/tmp

echo "mounted all dirs"
# create home directory
mkdir -p /mnt/home


# create boot directory
mkdir -p /mnt/boot/efi

mount "${BOOT_PARTITION}" /mnt/boot

mkdir -p /mnt/boot/efi

# mount the EFI partiton
mount "${EFI_PARTITION}" /mnt/boot/efi


# show the mounted partitions
lsblk

pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
echo "pc recv"
pacman-key --lsign-key 3056513887B78AEB
echo "pc lsi"
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
echo "pc u kr"
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo "pc u ml"

echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | tee -a /etc/pacman.conf

pacman -Sy  --noconfirm crudini dos2unix
crudini --set /etc/pacman.conf options ParallelDownloads 256
# crudini --set /mnt/etc/pacman.conf options ParallelDownloads 32

pacman -Sy --noconfirm archlinux-keyring
# pacman-key --refresh-keys
# pacman-key --populate archlinux


# install necessary packages
# pacstrap -K /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware lvm2 vim git networkmanager refind os-prober efibootmgr iwd amd-ucode crudini cryptsetup
pacstrap -K /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware lvm2 vim git networkmanager refind os-prober efibootmgr iwd crudini cryptsetup amd-ucode intel-ucode iw

# refind-install hook
cat <<EOF >/etc/pacman.d/hooks/refind.hook
[Trigger]
Operation=Upgrade
Type=Package
Target=refind

[Action]
Description = Updating rEFInd on ESP
When=PostTransaction
Exec=/usr/bin/refind-install
EOF


echo "refind-install hook"

# Generate an fstab config
genfstab -U /mnt > /mnt/etc/fstab

echo "genfstab"

cat /mnt/etc/fstab

# copy chroot-script.sh to /mnt
cp chroot-script.sh /mnt

cp mkinitcpio.conf mkinitcpio.conf_cp
mv -f mkinitcpio.conf_cp /mnt/etc/mkinitcpio.conf
dos2unix /mnt/etc/mkinitcpio.conf

echo "cp chroot-script.sh /mnt"

# chroot into the new system and run the chroot-script.sh script
arch-chroot /mnt ./chroot-script.sh

echo "arch-chroot /mnt ./chroot-script.sh"

# get the UUID of the LUKS partition
LUKS_UUID=$(blkid -s UUID -o value "${NEW_PARTITION}")

echo "luks uuid $LUKS_UUID"

# prepare boot options for refind
BOOT_OPTIONS="cryptdevice=UUID=${LUKS_UUID}:cryptlvm:allow-discards root=/dev/vg1/root"
RW_LOGLEVEL_OPTIONS="rw loglevel=3"
# INITRD_OPTIONS="initrd=amd-ucode.img initrd=initramfs-%v.img"
# INITRD_OPTIONS="add_efi_memmap initrd=intel-ucode.img initrd=amd-ucode.img initrd=initramfs-%v.img"
INITRD_OPTIONS="add_efi_memmap"
# configure refind
cat <<EOF >/mnt/boot/refind_linux.conf
"Boot with standard options"     "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS}"
"Boot with nomodeset"               "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} nomodeset"
"Boot using fallback initramfs"  "${BLK_OPTIONS} ${RW_LOGLEVEL_OPTIONS} initrd=intel-ucode.img initrd=amd-ucode.img initrd=initramfs-%v-fallback.img"
"Boot using fallback initramfs with nomodeset"  "${BLK_OPTIONS} ${RW_LOGLEVEL_OPTIONS} initrd=intel-ucode.img initrd=amd-ucode.img initrd=initramfs-%v-fallback.img nomodeset"
"Boot to terminal"               "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} systemd.unit=multi-user.target"
"Boot to terminal with nomodeset"               "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} systemd.unit=multi-user.target nomodeset"
"Boot to single-user mode"       "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} single"
"Boot to terminal with nomodeset"               "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} single nomodeset"
"Boot with minimal options"      "${BLK_OPTIONS} ${INITRD_OPTIONS} ro"
"Boot with minimal options with nomodeset"      "${BLK_OPTIONS} ${INITRD_OPTIONS} ro nomodeset"
EOF

echo "cat /mnt/boot/refind_linux.conf"
cat /mnt/boot/refind_linux.conf
echo ""
# sed -i 's|#extra_kernel_version_strings|extra_kernel_version_strings|' /mnt/boot/efi/EFI/refind/refind.conf
echo 'extra_kernel_version_strings "linux-hardened,linux-rt-lts,linux-zen,linux-lts,linux-rt,linux"' | sudo tee -a /mnt/boot/efi/EFI/refind/refind.conf
sudo sed -i 's|#fold_linux_kernels|fold_linux_kernels|' /mnt/boot/efi/EFI/refind/refind.conf

echo "sed refind stuff"

set +euo pipefail
mkdir -p /mnt/boot/efi/EFI/refind/themes
git clone https://github.com/BPplays/refind-catp.git /mnt/boot/efi/EFI/refind/themes/catppuccin
if [ -f /mnt/boot/efi/EFI/refind/themes/catppuccin/mocha.conf ]; then
    echo "include themes/catppuccin/mocha.conf" | sudo tee -a /mnt/boot/efi/EFI/refind/refind.conf
else
    echo "The file /mnt/boot/efi/EFI/refind/themes/catppuccin/mocha.conf does not exist."
fi
set -euo pipefail


# # unmount partitions
# umount /mnt/home
# umount /mnt/boot
# umount /mnt


echo "finished installing arch"
