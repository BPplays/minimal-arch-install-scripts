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

giga___10_power_9=1000000000

arch_size_b=$(expr $arch_size_gb \* $giga___10_power_9)

# if the user wants to create [one] LUKS partition manually with cfdisk (in case there are already other OS's installed)
if [ "${PARTITIONING}" == "y" ]; then
    # partition the block device with cfdisk
    cfdisk "${BLOCK_DEVICE}"
else
    # make a 550 MB EFI partition along with a $arch_size_b LUKS partition, leave the rest of the space unallocated
    sgdisk --clear -n 1:0:+1000000000 -t 1:ef00 -n "2:0:+${arch_size_b}" -t 2:8e00 "${BLOCK_DEVICE}"

    # format EFI partition
    mkfs.fat -F32 "${BLOCK_DEVICE}p1"
fi

# show partitions
lsblk

# read the boot/efi partition path
echo -n "Enter the boot/efi partition path: "
read -r BOOT_PARTITION

# read the LUKS partition path
echo -n "Enter the LUKS partition path: "
read -r NEW_PARTITION

# create a LUKS partiton
cryptsetup luksFormat "${NEW_PARTITION}"

# open the LUKS partition
cryptsetup open "${NEW_PARTITION}" cryptlvm

# create physical volume on the LUKS partition
pvcreate /dev/mapper/cryptlvm

# create logical volume group on the physical volume
vgcreate vg1 /dev/mapper/cryptlvm


# Replace 'your_vg_name' with the actual name of your volume group
VG_NAME="cryptlvm"

# Get the total size of the volume group in MB
VG_SIZE_MB=$(vgdisplay --units M $VG_NAME | grep "VG Size" | awk '{print int($3)}')

# Calculate 1% of the VG size in MB
PERCENT_SIZE_MB=$((VG_SIZE_MB / 100))

# Define the minimum size in MiB (10GB)
MIN_SIZE_MB=$((10 * 1000))

# Use the larger of the calculated size and the minimum size
LV_SIZE_MIB=$((PERCENT_SIZE_MB > MIN_SIZE_MIB ? PERCENT_SIZE_MB : MIN_SIZE_MB))

# Create the logical volume with the calculated size
lvcreate -L ${LV_SIZE_MB}M -nvar_log $VG_NAME
lvcreate -L ${LV_SIZE_MB}M -n var_cache $VG_NAME
lvcreate -L ${LV_SIZE_MB}M -n var_tmp $VG_NAME
lvcreate -L ${LV_SIZE_MB}M -n tmp $VG_NAME

# create logical volume named home on the volume group with the rest of the space
lvcreate -l 95%FREE vg1 -n root

# format root lv partition with ext4 filesystem
mkfs.ext4 -m 1 /dev/vg1/root

# format home lv partition with ext4 filesystem
mkfs.ext4 -m 1 /dev/vg1/home

# mount the root partition
mount /dev/vg1/root /mnt

# create home directory
mkdir -p /mnt/home

# mount the home partition
mount /dev/vg1/home /mnt/home

# create boot directory
mkdir -p /mnt/boot

# mount the EFI partiton
mount "${BOOT_PARTITION}" /mnt/boot

# show the mounted partitions
lsblk

# install necessary packages
pacstrap -K /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware lvm2 vim git networkmanager refind os-prober efibootmgr iwd intel-ucode

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

# Generate an fstab config
genfstab -U /mnt >>/mnt/etc/fstab

# copy chroot-script.sh to /mnt
cp chroot-script.sh /mnt

# chroot into the new system and run the chroot-script.sh script
arch-chroot /mnt ./chroot-script.sh

# get the UUID of the LUKS partition
LUKS_UUID=$(blkid -s UUID -o value "${NEW_PARTITION}")

# prepare boot options for refind
BLK_OPTIONS="cryptdevice=UUID=${LUKS_UUID}:cryptlvm root=/dev/vg1/root"
RW_LOGLEVEL_OPTIONS="rw loglevel=3"
INITRD_OPTIONS="initrd=intel-ucode.img initrd=initramfs-%v.img"
# configure refind
cat <<EOF >/mnt/boot/refind_linux.conf
"Boot with standard options"     "${BLK_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS}"
"Boot using fallback initramfs"  "${BLK_OPTIONS} ${RW_LOGLEVEL_OPTIONS} initrd=intel-ucode.img initrd=initramfs-%v-fallback.img"
"Boot to terminal"               "${BLK_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} systemd.unit=multi-user.target"
"Boot to single-user mode"       "${BLK_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} single"
"Boot with minimal options"      "${BLK_OPTIONS} ${INITRD_OPTIONS} ro"
EOF
sed -i 's|#extra_kernel_version_strings|extra_kernel_version_strings|' /mnt/boot/EFI/refind/refind.conf
sudo sed -i 's|#fold_linux_kernels|fold_linux_kernels|' /mnt/boot/EFI/refind/refind.conf

# unmount partitions
umount /mnt/home 
umount /mnt/boot 
umount /mnt
