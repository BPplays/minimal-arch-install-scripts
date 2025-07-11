#!/bin/bash

set -euo pipefail

pacman -Sy  --noconfirm bc btrfs-progs


convert_to_floor_512mult_int() {
	local in=$1
	local out=$(echo "scale=0; $in - ( $in % 512 )" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')

	echo "$out"
}


convert_bytes_gib() {
	local bytes=$1
	local gib=$(echo "$bytes / (1024^3)" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')

	echo "$gib"  # Return both values
}

convert_bytes_mib() {
	local bytes=$1
	local mib=$(echo "$bytes / (1024^2)" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')

	echo "$mib"  # Return both values
}


convert_bytes_kib() {
	local bytes=$1
	local kib=$(echo "$bytes / 1024" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')

	echo "$kib"  # Return both values
}


convert_bytes_gb() {
	local bytes=$1
	local gb=$(echo "$bytes / (1000^3)" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')

	echo "$gb"  # Return both values
}

convert_bytes_mb() {
	local bytes=$1
	local mb=$(echo "$bytes / (1000^2)" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')

	echo "$mb"  # Return both values
}

convert_gib_to_mib() {
	local gib="$1"
	local mib=$(echo "$gib * 1024" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')
	echo "$mib"
}

convert_gb_to_mib() {
	if [ -z "$1" ]; then
		echo "Usage: convert_gb_to_mib <size_in_GB>"
		return 1
	fi

	size_in_gb=$1
	echo "$(echo "($size_in_gb) * (1000000000 / 1048576)" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')"
}



convert_gib_to_byte() {
	local gib="$1"
	echo "$(echo "$gib * (2^30)" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')"
}

convert_gb_to_byte() {
	if [ -z "$1" ]; then
		echo "Usage: convert_gb_to_mib <size_in_GB>"
		return 1
	fi

	local size_in_gb=$1
	echo "$(echo "$size_in_gb * (10^9)" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')"
}


convert_gb_to_kib() {
	if [ -z "$1" ]; then
		echo "Usage: convert_gb_to_mib <size_in_GB>"
		return 1
	fi

	local size_in_gb=$1
	echo "$(echo "$size_in_gb * ((10^9) / 1024)" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')"
}

convert_gb_to_kb() {
	if [ -z "$1" ]; then
		echo "Usage: convert_gb_to_mib <size_in_GB>"
		return 1
	fi

	local size_in_gb=$1
	echo "$(echo "$size_in_gb * (10^6)" | bc -l | sed -E -e 's!(\.[0-9]*[1-9])0*$!\1!' -e 's!(\.0*)$!!')"
}




get_swap_size() {
	# local bytes=$1
	# local gib=$(echo "scale=4; $bytes / (1024^3)" | bc)
	# local gb=$(echo "scale=4; $bytes / (1000^3)" | bc)
	if [ "$ram_si" == "true" ]; then
		echo $(convert_to_floor_512mult_int $(convert_gb_to_byte $SWAP_SIZE))
	else
		echo $(convert_to_floor_512mult_int $(convert_gib_to_byte $SWAP_SIZE))
	fi

}


print_silsblk() {
	lsblk_out=$(lsblk --bytes | numfmt --field 4 --header --to=si --format="%.2f")
	# to_3rd_col=$(echo "$lsblk_out" | awk '{for (i = length($0); i > 0; i--) if (substr($0, i, 1) == substr($3, 1, 1) && substr($0, i, length($3)) == $3) {print i + length($3) - 1; break}}' | sort -n | tail -n 1)
	#
	# to_4rd_col_start=$(echo "$lsblk_out" | awk '{for (i = length($0); i > 0; i--) if (substr($0, i, 1) == substr($4, 1, 1) && substr($0, i, length($4)) == $4) {print i; break}}' | sort -n | head -n 1)


	# base_awk=$(echo "$lsblk_out" | awk '{
	#     # Find the end index of column 3
	#     match($0, /[^ ]+ +[^ ]+ +[^ ]+/)
	#     end_col3 = RSTART + RLENGTH - 1
	#
	#     # Find the start index of column 4
	#     match(substr($0, end_col3 + 1), /[^ ]+/)
	#     start_col4 = end_col3 + RSTART
	#
	#     print "End of column 3:", end_col3, "Start of column 4:", start_col4
	# }')

	to_3rd_col=$(echo "$lsblk_out" | awk '{
		if (NF >= 4) {
			# Find the end index of column 3
			match($0, /[^ ]+ +[^ ]+ +[^ ]+/)
			end_col3 = RSTART + RLENGTH - 1

			# Find the start index of column 4
			match(substr($0, end_col3 + 1), /[^ ]+/)
			start_col4 = end_col3 + RSTART

			print end_col3
		}
	}' | sort -n | tail -n 1 )


	to_4rd_col_start=$(echo "$lsblk_out" | awk '{
		if (NF >= 4) {
			# Find the end index of column 3
			match($0, /[^ ]+ +[^ ]+ +[^ ]+/)
			end_col3 = RSTART + RLENGTH - 1

			# Find the start index of column 4
			match(substr($0, end_col3 + 1), /[^ ]+/)
			start_col4 = end_col3 + RSTART

			print start_col4
		}
	}' | sort -n | head -n 1)



	# spc_rmv=$((to_3rd_col - to_4rd_col_start))
	# num1=$((to_3rd_col + 1))
	# num2=$((to_4rd_col_start - 2))
	num1=$((to_3rd_col + 1))
	num2=$((to_4rd_col_start - 2))

	# modified_string=$(echo "$lsblk_out" | sed "${num1},${num2}d")
	# echo "$num1"
	# echo "$num2"
	# echo "$modified_string"

	result=""
	first_line=true
	while IFS= read -r line; do
		if [ "$first_line" = true ]; then
			first_line=false
		else
			result+="\n"
		fi
		result+="${line:0:num1-1}${line:num2}"
	done <<< "$lsblk_out"

	# Print the result string
	echo -e "$result"


}


# check if boot type is UEFI
ls /sys/firmware/efi/efivars || { echo "Boot Type Is Not UEFI!; "exit 1; }

# check if internet connection exists
ping -q -c 1 archlinux.org >/dev/null || { echo "No Internet Connection!; "exit 1; }

# update system clock
timedatectl set-ntp true

echo ""
echo ""
echo ""
echo ""



echo "============================================================================================"
echo "============================================================================================"
echo "===                                                                                      ==="
echo "=== ALL LSBLK RESULTS ARE CONVERTED TO SI PREFIXES, E.G. GB INSTEAD OF LSBLK DEFAULT GIB ==="
echo "===                                                                                      ==="
echo "============================================================================================"
echo "============================================================================================"
echo ""
echo ""
echo ""
echo ""

# lsblk --bytes | numfmt --field 4 --header --to=si --format="%.2f"
print_silsblk

echo ""


# read the block device path you want to install Arch on
echo -n "Enter the block device path you want to install Arch on: "
read -r BLOCK_DEVICE

# ask if the user wants default partitioning or wants to do partitioning manually with cfdisk?
echo -n "Do you want to do partitioning manually with cfdisk? [y/N]: "
read -r PARTITIONING

ram_bytes=$(free --bytes | grep 'Mem:' | awk '{print $2}')
ram_gb=$(convert_bytes_gb $ram_bytes)
ram_gib=$(convert_bytes_gib $ram_bytes)
echo ""
echo "RAM size: $ram_gb GB, $ram_gib GiB"
read -p "would you like to use si decimal prefixes for RAM and swap over base-2 prefixes (GB is si, GiB is base-2. base-2 is more standard for RAM and the default here)? [y/N]: " response
response=${response:-N}  # Default to 'Y' if no input

echo ""
if [[ "$response" =~ ^[Yy]$ ]]; then
	ram_si=true

	echo "RAM size $ram_gb GB"
	echo -n "Enter swap size in GB (nothing or 0 means no swap): "

	read -r SWAP_SIZE

else
	ram_si=false

	echo "RAM size $ram_gib GiB"
	echo -n "Enter swap size in GiB (nothing or 0 means no swap): "

	read -r SWAP_SIZE
fi


echo -n "main partition size GB: "
read -r arch_size_gb

# giga___10_power_9=1000000000
gb_to_gib=0.9313225746

final_tz=""
# Fetch estimated timezone
set +euo pipefail
auto_tz=$(curl -s https://ipapi.co/timezone/)
set -euo pipefail

# Ask user to confirm or input the correct timezone
echo "The estimated timezone based on your IP address is: $auto_tz"
read -e -p "Is this correct? (Y/n): " response

# Handle user input
response=${response:-Y}  # Default to 'Y' if no input

if [[ "$response" =~ ^[Yy]$ ]]; then
	# Set the detected timezone
	final_tz="$auto_tz"
else
	# Prompt user to enter the correct timezone
	read -p "Please enter your timezone (e.g., 'Asia/Tokyo', 'America/Los_Angeles', 'America/New_York'): " final_tz
	# echo "Setting timezone to $final_tz..."
fi

# echo -n "Enter Time Zone: "
# read -r TIME_ZONE_t
export TIME_ZONE="$final_tz"
echo "Using $TIME_ZONE as timezone"

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

while true; do
	# Prompt for the password
	read -s -p "Enter local_admin password: " password
	echo

	# Prompt for the confirmation
	read -s -p "Confirm password: " confirm_password
	echo

	# Check if passwords match
	if [ "$password" == "$confirm_password" ]; then
		# Export the variable
		export LOCAL_ADMIN_PASS="$password"

		break
	else
		echo "Passwords do not match. Please try again."
	fi
done

arch_size_GIB=$(echo "$arch_size_gb * $gb_to_gib" | bc)
arch_size_MIB=$(convert_gb_to_mib $arch_size_gb)
arch_size_KIB=$(convert_gb_to_kib $arch_size_gb)
arch_size_byte=$(convert_gb_to_byte $arch_size_gb)

# if the user wants to create [one] LUKS partition manually with cfdisk (in case there are already other OS's installed)
if [ "${PARTITIONING}" == "y" ]; then
	# partition the block device with cfdisk
	cfdisk "${BLOCK_DEVICE}"
else
	sgdisk --clear \
		-n 1:2048:+$(awk "BEGIN {print int($(convert_gb_to_kib 1.5))}")kib -t 1:EF00 -c 1:"Arch Linux-EFI System" \
		-n 2:0:+$(awk "BEGIN {print int($(convert_gb_to_kib 2))}")kib -t 2:ea00 -c 2:"Arch Linux-Boot" \
		-n 3:0:+$(awk "BEGIN {print int(${arch_size_KIB})}")kib -t 3:8309 -c 3:"Arch Linux" \
		"${BLOCK_DEVICE}"

	# format EFI partition
	mkfs.fat -F32 "${BLOCK_DEVICE}p1"
	mkfs.ext4 -m 2 "${BLOCK_DEVICE}p2"
fi

# show partitions
# lsblk --bytes | numfmt --field 4 --header --to=si --format="%.2f"
print_silsblk

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
		read -s -p "Enter luks disk encryption password: " password
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




	echo -n "$LUKS_PASS" | cryptsetup luksFormat "${NEW_PARTITION}" --key-file=- --cipher aes-xts-plain64 --hash sha256 --key-size 512

	# Break the loop if the command succeeds (exit code 0)
	if [[ $? -eq 0 ]]; then
		break
	fi

	# echo "Command failed. Retrying..."
	# sleep 2  # Optional: wait for 2 seconds before retrying
done

echo ""
echo ""
echo ""
echo ""
echo ""
echo "======================="
echo "======================="
echo "===                 ==="
echo "=== user input done ==="
echo "===                 ==="
echo "======================="
echo "======================="
echo ""
echo ""
echo ""
echo ""
echo ""


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
	break

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
lv_size_mib=$(convert_bytes_mib $lv_size_bytes)
lv_size_kib=$(convert_bytes_kib $lv_size_bytes)
lv_size_bytes_512=$(convert_to_floor_512mult_int $lv_size_bytes)

# Create the logical volume with the calculated size
lvcreate -L ${lv_size_bytes_512}b -n var_log $VG_NAME
lvcreate -L ${lv_size_bytes_512}b -n var_cache $VG_NAME
lvcreate -L ${lv_size_bytes_512}b -n var_tmp $VG_NAME
lvcreate -L ${lv_size_bytes_512}b -n tmp $VG_NAME


if [[ -z "$SWAP_SIZE" || "$SWAP_SIZE" == "0" ]]; then
	echo "skipping swap partition"
else
	echo "making swap partition"
	lvcreate -L "$(get_swap_size)b" -n swap_lv1 "$VG_NAME"
fi

# create logical volume named home on the volume group with the rest of the space
lvcreate -l 90%FREE vg1 -n root


# mkfs.btrfs --csum XXHASH /dev/vg1/root
# mkfs.btrfs --csum XXHASH /dev/vg1/var_log
# mkfs.btrfs --csum XXHASH /dev/vg1/var_cache
# mkfs.btrfs --csum XXHASH /dev/vg1/var_tmp

mkfs.ext4 -m 1 /dev/vg1/root
mkfs.ext4 -m 5 /dev/vg1/var_log
mkfs.ext4 -m 5 /dev/vg1/var_cache
mkfs.ext4 -m 5 /dev/vg1/var_tmp

mkfs.ext4 -m 5 /dev/vg1/tmp
tune2fs -O ^has_journal /dev/vg1/tmp


#! look into this might cause swap errors and crashes on fresh install?
if [[ -z "$SWAP_SIZE" || "$SWAP_SIZE" == "0" ]]; then
	sleep 0
else
	mkswap /dev/$VG_NAME/swap_lv1
	swapon /dev/$VG_NAME/swap_lv1
fi

# mount the root partition
# mount /dev/vg1/root /mnt
# btrfs subvolume create /mnt/@
# btrfs subvolume create /mnt/@home
# btrfs subvolume create /mnt/@var
# umount /mnt
#
#
# mount /dev/vg1/var_log /mnt/
# btrfs subvolume create /mnt/@
# umount /mnt
#
#
# mount /dev/vg1/var_cache /mnt
# btrfs subvolume create /mnt/@
# umount /mnt
#
#
#
# mount /dev/vg1/var_tmp /mnt
# btrfs subvolume create /mnt/@
# umount /mnt


# may not be needed check dumpe2fs
# e2fsck -Df /dev/vg1/root
# resize2fs -b /dev/vg1/root
# tune2fs -O metadata_csum /dev/vg1/root
#
# e2fsck -Df /dev/vg1/var_tmp
# resize2fs -b /dev/vg1/var_tmp
# tune2fs -O metadata_csum /dev/vg1/var_tmp
#
# e2fsck -Df /dev/vg1/var_cache
# resize2fs -b /dev/vg1/var_cache
# tune2fs -O metadata_csum /dev/vg1/var_cache
#
# e2fsck -Df /dev/vg1/var_log
# resize2fs -b /dev/vg1/var_log
# tune2fs -O metadata_csum /dev/vg1/var_tmp




# mount -o subvol=@ /dev/vg1/root /mnt
mount -o relatime /dev/vg1/root /mnt

mkdir -p /mnt/home
mkdir -p /mnt/var/log
mkdir -p /mnt/var/cache
mkdir -p /mnt/tmp
mkdir -p /mnt/var/tmp


# mount -o subvol=@var /dev/vg1/root /mnt/var

mkdir -p /mnt/home
mkdir -p /mnt/var/log
mkdir -p /mnt/var/cache
mkdir -p /mnt/tmp
mkdir -p /mnt/var/tmp


# mount -o subvol=@home /dev/vg1/root /mnt/home

# mount -o subvol=@ /dev/vg1/var_log /mnt/var/log
mount -o relatime /dev/vg1/var_log /mnt/var/log

# mount -o subvol=@ /dev/vg1/var_cache /mnt/var/cache
mount -o relatime /dev/vg1/var_cache /mnt/var/cache

# mount -o subvol=@ /dev/vg1/var_tmp /mnt/var/tmp
mount -o relatime /dev/vg1/var_tmp /mnt/var/tmp


mount -o relatime /dev/vg1/tmp /mnt/tmp

echo "mounted all dirs"
# create home directory
mkdir -p /mnt/home


# create boot directory
mkdir -p /mnt/boot/efi

mount "${BOOT_PARTITION}" /mnt/boot

mkdir -p /mnt/boot/efi

# mount the EFI partiton
mount "${EFI_PARTITION}" /mnt/boot/efi


# sudo btrfs subvolume create /opt/swap/
#
# # use binary 1M instead of 1MB because that is what RAM is built to
# sudo dd if=/dev/zero of=/opt/swap/swap1 bs=1M count=32768
#
# sudo chattr +C /opt/swap/
# sudo chattr +C /opt/swap/swap1
#
# sudo chmod -R 600 /opt/swap/
# sudo chmod 600 /opt/swap/swap1
#
# sudo mkswap /opt/swap/swap1
#
# # i don't know if this gets in fstab by default will make it work in ansible
# # sudo swapon /opt/swap/swap1


# show the mounted partitions
# lsblk --bytes | numfmt --field 4 --header --to=si --format="%.2f"
print_silsblk

pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
echo "pc recv"
pacman-key --lsign-key 3056513887B78AEB
echo "pc lsi"
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
echo "pc u kr"
pacman -U  --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo "pc u ml"

echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | tee -a /etc/pacman.conf

pacman -Sy  --noconfirm dos2unix e2fsprogs
python -m venv venv
source venv/bin/activate
pip install crudini

# pacman -Sy  --noconfirm crudini dos2unix e2fsprogs
crudini --set /etc/pacman.conf options ParallelDownloads 64
# crudini --set /mnt/etc/pacman.conf options ParallelDownloads 32

pacman -Sy --noconfirm archlinux-keyring
# pacman-key --refresh-keys
# pacman-key --populate archlinux


# install necessary packages
# pacstrap -K /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware lvm2 vim git networkmanager refind os-prober efibootmgr iwd amd-ucode crudini cryptsetup

pacstrap -K /mnt base base-devel linux linux-headers linux-docs linux-firmware lvm2 vim git networkmanager refind os-prober efibootmgr iwd cryptsetup amd-ucode intel-ucode iw wireless-regdb fprintd openssh dos2unix pipewire pipewire-audio pipewire-pulse pipewire-alsa wireplumber pipewire-jack lzop btrfs-progs mesa vulkan-radeon libva-mesa-driver realtime-privileges rtkit pipewire-docs bluez bluez-utils openssh acpi python iptables-nft
pacstrap -K /mnt linux-lts linux-lts-headers linux-lts-docs linux-zen linux-zen-docs linux-zen-headers linux-rt linux-rt-headers linux-rt-docs python

# extra kernels
# pacstrap -K /mnt linux-hardened linux-hardened-headers linux-hardened-docs linux-rt-lts linux-rt-lts-headers linux-rt-lts-docs

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
fstab_no_fsck_tmp=$(awk '$2 == "/tmp" { $6 = "0" }1' /mnt/etc/fstab)
echo "$fstab_no_fsck_tmp" > /mnt/etc/fstab

echo "genfstab"

cat /mnt/etc/fstab

# copy chroot-script.sh to /mnt
mkdir -p /mnt/opt/arch_install_sh
cp chroot-script.sh /mnt/opt/arch_install_sh/
dos2unix /mnt/opt/arch_install_sh/*

cp mkinitcpio.conf mkinitcpio.conf_cp
mv -f mkinitcpio.conf_cp /mnt/etc/mkinitcpio.conf
dos2unix /mnt/etc/mkinitcpio.conf


cp vconsole.conf vconsole.conf_cp
mv -f vconsole.conf_cp /mnt/etc/vconsole.conf
dos2unix /mnt/etc/vconsole.conf


cp wifi_backend.conf wifi_backend.conf_cp
mkdir -p /mnt/etc/NetworkManager/conf.d/
mv -f wifi_backend.conf_cp /mnt/etc/NetworkManager/conf.d/wifi_backend.conf
dos2unix /mnt/etc/NetworkManager/conf.d/wifi_backend.conf


cp wireless-regdom wireless-regdom_cp
mkdir -p /mnt/etc/conf.d/
mv -f wireless-regdom_cp /mnt/etc/conf.d/wireless-regdom
dos2unix /mnt/etc/conf.d/wireless-regdom

# echo "cp chroot-script.sh /mnt"


mkdir -p /mnt/etc/pacman.d/hooks/
cp -r ./pacmanhooks/* /mnt/etc/pacman.d/hooks/
dos2unix /mnt/etc/pacman.d/hooks/*

cp aur_freeipa_get_key.sh /mnt/usr/local/sbin/
sudo chmod 755 /mnt/usr/local/sbin/aur_freeipa_get_key.sh
dos2unix /mnt/usr/local/sbin/aur_freeipa_get_key.sh

if [ -f "./post_install.sh" ]; then
	# If it exists, move it to ./Post_install.sh
	mv -f ./post_install.sh ./Post_install.sh
	echo "File renamed to ./Post_install.sh"
fi

cp Post_install.sh /mnt/usr/local/bin/
sudo chmod 755 /mnt/usr/local/bin/Post_install.sh
dos2unix /mnt/usr/local/bin/Post_install.sh

# chroot into the new system and run the chroot-script.sh script
arch-chroot /mnt ./opt/arch_install_sh/chroot-script.sh

echo "arch-chroot /mnt ./chroot-script.sh"

# get the UUID of the LUKS partition
LUKS_UUID=$(blkid -s UUID -o value "${NEW_PARTITION}")

echo "luks uuid $LUKS_UUID"


# cat <<EOF >/mnt/etc/crypttab
# cryptlvm    UUID=${LUKS_UUID}    none    luks
# EOF

# prepare boot options for refind
BOOT_OPTIONS="rd.luks.uuid=${LUKS_UUID} cryptdevice=UUID=${LUKS_UUID}:cryptlvm:allow-discards root=/dev/vg1/root"
# RW_LOGLEVEL_OPTIONS="rw loglevel=4"
RW_LOGLEVEL_OPTIONS="rw"
# INITRD_OPTIONS="initrd=amd-ucode.img initrd=initramfs-%v.img"
# INITRD_OPTIONS="add_efi_memmap initrd=intel-ucode.img initrd=amd-ucode.img initrd=initramfs-%v.img"
INITRD_OPTIONS="add_efi_memmap"
# MISC_PARAMS="efi_pstore.pstore_disable=0 panic=5 zswap.enabled=0"
# MISC_PARAMS="efi_pstore.pstore_disable=0 panic=5 iommu=soft"
MISC_PARAMS="efi_pstore.pstore_disable=0 panic=5"
# configure refind
cat <<EOF >/mnt/boot/refind_linux.conf
"Boot"     "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS}"
"Boot with nomodeset"               "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} nomodeset"
"Boot using fallback initramfs"  "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} initrd=intel-ucode.img initrd=amd-ucode.img initrd=initramfs-%v-fallback.img"
"Boot using fallback initramfs with nomodeset"  "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} initrd=intel-ucode.img initrd=amd-ucode.img initrd=initramfs-%v-fallback.img nomodeset"
"Boot to terminal"               "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} systemd.unit=multi-user.target"
"Boot to terminal with nomodeset"               "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} systemd.unit=multi-user.target nomodeset"
"Boot to terminal single user with nomodeset"               "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} single nomodeset"
"Boot to single-user mode"       "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} single"
"Boot to single-user mode with nomodeset"       "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} single nomodeset"
"Boot with minimal options"      "${BOOT_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} ro"
"Boot with minimal options with nomodeset"      "${BOOT_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} ro nomodeset"
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
echo ""
echo ""
echo ""

set +euo pipefail

echo "fstab:"
cat /mnt/etc/fstab

echo ""
echo ""
echo ""

echo "final partition layout:"
print_silsblk


echo ""
echo ""
echo ""

echo "================================"
echo "================================"
echo "===                          ==="
echo "=== finished installing arch ==="
echo "===                          ==="
echo "================================"
echo "================================"

echo ""

set -euo pipefail


