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
# print_silsblk

BLOCK_DEVICE=""

select_disk() {
	local selected=""

	while [[ -z "$selected" ]]; do
		local json
		json=$(lsblk --json --bytes -d -e 7 -o NAME,SIZE,MODEL,TYPE,TRAN)

		local -a disks=()
		mapfile -t disks < <(
			jq -c '
				.blockdevices[]
				| select(.type == "disk")
			' <<< "$json"
		)

		echo >&2
		echo "Available disks:" >&2
		echo >&2

		local table=""
		local -a selectable_disks=()
		local display_index=0
		local disk

		for disk in "${disks[@]}"; do
			local name size model tran

			name=$(jq -r '.name' <<< "$disk")
			size=$(jq -r '.size' <<< "$disk")
			model=$(jq -r '.model // ""' <<< "$disk")
			tran=$(jq -r '.tran // ""' <<< "$disk")

			local path="/dev/$name"

			[[ -b "$path" ]] || continue

			((++display_index))
			selectable_disks+=("$disk")

			table+=$(printf '%d)\t%s\t%s GB\t%s' \
				"$display_index" \
				"$path" \
				"$(convert_bytes_gb "$size")" \
				"$model")

			[[ -n "$tran" ]] && table+=$'\t'"[$tran]"
			table+=$'\n'
		done

		printf '%s' "$table" | column -t -s $'\t' >&2

		echo >&2
		read -e -p "Choose the block device path you want to install Arch on: " choice

		if [[ "$choice" == "0" ]]; then
			return 1
		elif [[ "$choice" =~ ^[1-9][0-9]*$ ]] &&
			(( choice <= ${#selectable_disks[@]} )); then

			local name
			name=$(jq -r '.name' <<< "${selectable_disks[$((choice - 1))]}")

			selected="/dev/$name"
		fi
	done

	printf '%s\n' "$selected"
}

while [[ -z "$BLOCK_DEVICE" ]]; do
	BLOCK_DEVICE=$(select_disk) || continue
done

echo "Using $BLOCK_DEVICE as install drive"
echo ""

# ask if the user wants default partitioning or wants to do partitioning manually with cfdisk?
echo -n "Do you want to do partitioning manually with cfdisk? [y/N]: "
read -r PARTITIONING

ram_bytes=$(free --bytes | grep 'Mem:' | awk '{print $2}')
ram_gb=$(convert_bytes_gb $ram_bytes)
ram_gib=$(convert_bytes_gib $ram_bytes)
echo ""
echo "RAM size: $ram_gb GB, $ram_gib GiB"
read -p "would you like to use si decimal prefixes for RAM and swap over base-2 prefixes (GB is si, GiB is base-2. base-2 is more standard for RAM and the default here)? [y/N]: " response
response=${response:-N}

ram_si=false
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



case "$(uname -m)" in
    x86_64)
        arch="amd64"
        ;;
    aarch64|arm64)
        arch="arm64"
        ;;
    *)
        echo "Unsupported architecture: $(uname -m); skipping get_tz_dhcp"
        arch=""
        ;;
esac

if [[ -n "$arch" ]]; then
	mkdir -p /mnt/opt/arch_install_sh
    cp "./bin/$arch/get_tz_dhcp" /mnt/opt/arch_install_sh/
fi

final_tz=""
auto_tz=""
tz_msg="<broken auto timezone msg>"

# Cache the valid timezone list once.
mapfile -t valid_timezones < <(timedatectl list-timezones)

timezone_is_valid() {
    local tz="$1"
    printf '%s\n' "${valid_timezones[@]}" | grep -Fxq -- "$tz"
}

timezone_find_case_insensitive() {
    local input="$1"
    local tz

    for tz in "${valid_timezones[@]}"; do
        if [[ "${tz,,}" == "${input,,}" ]]; then
            printf '%s\n' "$tz"
            return 0
        fi
    done

    return 1
}

# Return up to 5 timezone names most similar to the input using Jaro-Winkler.
find_similar_timezones() {
    local input="$1"

    TIMEZONES="$(printf '%s\n' "${valid_timezones[@]}")" \
        python3 - "$input" <<'PY'
import os
import sys


def jaro(s1: str, s2: str) -> float:
    if s1 == s2:
        return 1.0

    len1 = len(s1)
    len2 = len(s2)

    if not len1 or not len2:
        return 0.0

    match_distance = max(len1, len2) // 2 - 1

    if match_distance < 0:
        match_distance = 0

    matches1 = [False] * len1
    matches2 = [False] * len2

    matches = 0

    for i, c1 in enumerate(s1):
        start = max(0, i - match_distance)
        end = min(i + match_distance + 1, len2)

        for j in range(start, end):
            if matches2[j] or c1 != s2[j]:
                continue

            matches1[i] = True
            matches2[j] = True
            matches += 1
            break

    if not matches:
        return 0.0

    matched1 = [s1[i] for i in range(len1) if matches1[i]]
    matched2 = [s2[j] for j in range(len2) if matches2[j]]

    transpositions = sum(a != b for a, b in zip(matched1, matched2)) / 2

    return (
        matches / len1
        + matches / len2
        + (matches - transpositions) / matches
    ) / 3


def jaro_winkler(s1: str, s2: str) -> float:
    s1 = s1.lower()
    s2 = s2.lower()

    score = jaro(s1, s2)

    # Standard Jaro-Winkler prefix length, capped at 4.
    prefix = 0
    for a, b in zip(s1, s2):
        if a != b or prefix == 4:
            break
        prefix += 1

    return score + prefix * 0.1 * (1.0 - score)


input_tz = sys.argv[1]
timezones = os.environ["TIMEZONES"].splitlines()

slash_count = input_tz.count("/")

if slash_count == 1:
    # Input has Region/City: compare both blocks separately.
    input_blocks = input_tz.split("/")
    input_has_region = True
else:
    # Input has no slash: treat it as a city/location block only.
    input_blocks = [input_tz]
    input_has_region = False


results = []

for timezone in timezones:
    if not timezone:
        continue

    candidate_blocks = timezone.split("/")

    if input_has_region and len(candidate_blocks) == 2:
        region_score = jaro_winkler(
            input_blocks[0],
            candidate_blocks[0],
        )

        city_score = jaro_winkler(
            input_blocks[1],
            candidate_blocks[1],
        )

        # Overall similarity of both components.
        score = (region_score + city_score) / 2.0

        # Modest bonus for an exact region match.
        if input_blocks[0].lower() == candidate_blocks[0].lower():
            score += 0.05

    else:
        # No slash in the input: compare only against the city/location
        # portion of the candidate timezone.
        city = candidate_blocks[-1]
        score = jaro_winkler(input_blocks[0], city)

    results.append((score, timezone))


# Highest score first, then alphabetically for deterministic ties.
results.sort(key=lambda x: (-x[0], x[1]))

for score, timezone in results[:5]:
    print(timezone)
PY
}

# Fetch estimated timezone
set +euo pipefail

if [[ -n "$arch" ]]; then
    candidate_tz=$(/mnt/opt/arch_install_sh/get_tz_dhcp -doTzdb -newAddress)

    # Only accept DHCPv6 result if systemd recognizes it.
    if [[ -n "$candidate_tz" ]] && timezone_is_valid "$candidate_tz"; then
        auto_tz="$candidate_tz"
        tz_msg="The timezone based on DHCPv6 is:"
    fi
fi

if [[ -z "$auto_tz" ]]; then
    candidate_tz=$(curl -fsL https://ipapi.co/timezone/)

    # Only accept IP result if systemd recognizes it.
    if [[ -n "$candidate_tz" ]] && timezone_is_valid "$candidate_tz"; then
        auto_tz="$candidate_tz"
        tz_msg="The estimated timezone based on your IP address is:"
    fi
fi

set -euo pipefail

# Ask user to confirm detected timezone
if [[ -n "$auto_tz" ]]; then
    echo "$tz_msg $auto_tz"
    read -e -p "Is this correct? (Y/n): " response
    response=${response:-Y}

    if [[ "$response" =~ ^[Yy]$ ]]; then
        final_tz="$auto_tz"
    fi
fi

# Manual timezone entry
while [[ -z "$final_tz" ]]; do
    read -e -p "Please enter your timezone (e.g., 'Asia/Tokyo', 'America/Los_Angeles', 'America/New_York'): " entered_tz

    if timezone_is_valid "$entered_tz"; then
        final_tz="$entered_tz"
        break
    fi

    # Case-insensitive exact match.
    if corrected_tz=$(timezone_find_case_insensitive "$entered_tz"); then
        final_tz="$corrected_tz"
        break
    fi

    echo "Invalid timezone: $entered_tz"
    echo

    mapfile -t suggestions < <(find_similar_timezones "$entered_tz")

    if ((${#suggestions[@]} > 0)); then
        echo "Possible matches:"
        for i in "${!suggestions[@]}"; do
            printf '  %d) %s\n' "$((i + 1))" "${suggestions[i]}"
        done
        echo
		printf '  0) %s\n' "Retype"
        echo

        read -e -p "Enter a number to use a suggested timezone, or press Enter to retype: " choice

		if [[ "$choice" == "0" ]]; then
			# special case for 0
			final_tz=""
		elif [[ "$choice" =~ ^[1-9][0-9]*$ ]] &&
           (( choice <= ${#suggestions[@]} )); then
            final_tz="${suggestions[$((choice - 1))]}"
        fi
    else
        echo "No similar timezones found."
    fi
done

export TIME_ZONE="$final_tz"
echo "Using timezone: $TIME_ZONE"


while true; do
	echo "Choose system type:"
	echo "1) desktop"
	echo "2) laptop"
	echo "3) server"
	read -rp "Enter choice [1-3]: " choice

	case "$choice" in
		1)
			system_label="desktop"
			extra_kern_params="preempt=full nohz_full=all threadirqs"
			;;
		2)
			system_label="laptop"
			extra_kern_params="preempt=full rcu_nocbs=all rcutree.enable_rcu_lazy=1"
			;;
		3)
			system_label="server"
			extra_kern_params=""
			;;
		*)
			system_label="other"
			extra_kern_params=""
			;;
	esac

	echo
	echo "You selected: $system_label"
	echo "Kernel params: ${extra_kern_params:-<none>}"
	read -rp "Is this correct? [y/N]: " confirm

	case "$confirm" in
		[yY]|[yY][eE][sS])
			break
			;;
		*)
			# echo "Okay, let's try again."
			echo
			;;
	esac
done

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

select_partition() {
	local prompt="$1"
	shift

	local selected=""

	# Partition paths that should not be offered again.
	local -A excluded_partitions=()
	local partition_to_exclude

	for partition_to_exclude in "$@"; do
		excluded_partitions["$partition_to_exclude"]=1
	done

	while [[ -z "$selected" ]]; do
		local json
		json=$(lsblk --json --bytes -e 7 -o NAME,SIZE,TYPE,FSTYPE,LABEL,PARTTYPE)

		local -a partitions=()
		mapfile -t partitions < <(
			jq -c '
				.blockdevices[]
				| .. | objects
				| select(.type == "part")
			' <<< "$json"
		)

		echo >&2
		echo "Available partitions:" >&2
		echo >&2

		local table=""
		local -a selectable_partitions=()
		local display_index=0
		local partition

		for partition in "${partitions[@]}"; do
			local name size fstype label

			name=$(jq -r '.name' <<< "$partition")
			size=$(jq -r '.size' <<< "$partition")
			fstype=$(jq -r '.fstype // ""' <<< "$partition")
			label=$(jq -r '.label // ""' <<< "$partition")

			local path="/dev/$name"

			[[ -b "$path" ]] || continue


			# increment first to keep order the same even with excluded
			((++display_index))

			# Don't offer partitions that were already selected.
			[[ -n "${excluded_partitions[$path]+x}" ]] && continue

			selectable_partitions+=("$partition")

			table+=$(printf '%d)\t%s\t%s GB' \
				"$display_index" \
				"$path" \
				"$(convert_bytes_gb "$size")")

			[[ -n "$fstype" ]] && table+=$'\t'"[$fstype]"
			[[ -n "$label" ]] && table+=$'\t'"\"$label\""
			table+=$'\n'
		done

		printf '%s' "$table" | column -t -s $'\t' >&2

		echo >&2
		read -e -p "$prompt: " choice

		if [[ "$choice" == "0" ]]; then
			return 1
		elif [[ "$choice" =~ ^[1-9][0-9]*$ ]] &&
			(( choice <= ${#selectable_partitions[@]} )); then

			local name
			name=$(jq -r '.name' <<< "${selectable_partitions[$((choice - 1))]}")
			selected="/dev/$name"
		fi
	done

	printf '%s\n' "$selected"
}

if [[ "${PARTITIONING}" == "y" ]]; then
	echo
	echo "You should make at least 3 partitions: EFI, BOOT, and a main LUKS partition"
	echo
	read -r -p "Press Enter to continue..."

	cfdisk "${BLOCK_DEVICE}"

	echo
	echo "Select the partitions to use for the Arch installation."
	echo

	EFI_PARTITION=$(select_partition "Choose the EFI system partition") || exit 1
	BOOT_PARTITION=$(select_partition "Choose the boot partition" "$EFI_PARTITION") || exit 1
	NEW_PARTITION=$(select_partition "Choose the LUKS partition" "$EFI_PARTITION" "$BOOT_PARTITION") || exit 1
else
	sgdisk --clear \
		-n 1:2048:+$(awk "BEGIN {print int($(convert_gb_to_kib 1.5))}")kib -t 1:EF00 -c 1:"Arch Linux-EFI System" \
		-n 2:0:+$(awk "BEGIN {print int($(convert_gb_to_kib 2))}")kib -t 2:ea00 -c 2:"Arch Linux-Boot" \
		-n 3:0:+$(awk "BEGIN {print int(${arch_size_KIB})}")kib -t 3:8309 -c 3:"Arch Linux" \
		"${BLOCK_DEVICE}"

	EFI_PARTITION="${BLOCK_DEVICE}p1"
	BOOT_PARTITION="${BLOCK_DEVICE}p2"
	NEW_PARTITION="${BLOCK_DEVICE}p3"

	mkfs.fat -F32 "$EFI_PARTITION"
	mkfs.ext4 -m 2 "$BOOT_PARTITION"
fi

# show partitions
# lsblk --bytes | numfmt --field 4 --header --to=si --format="%.2f"
print_silsblk

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


mkfs.btrfs --csum XXHASH /dev/vg1/root
mkfs.btrfs --csum XXHASH /dev/vg1/var_log
mkfs.btrfs --csum XXHASH /dev/vg1/var_cache
mkfs.btrfs --csum XXHASH /dev/vg1/var_tmp

# mkfs.ext4 -m 1 /dev/vg1/root
# mkfs.ext4 -m 5 /dev/vg1/var_log
# mkfs.ext4 -m 5 /dev/vg1/var_cache
# mkfs.ext4 -m 5 /dev/vg1/var_tmp

mkfs.ext4 -m 5 /dev/vg1/tmp
tune2fs -O ^has_journal /dev/vg1/tmp


#! look into this might cause swap errors and crashes on fresh install?
if [[ -z "$SWAP_SIZE" || "$SWAP_SIZE" == "0" ]]; then
	sleep 0
else
	mkswap /dev/$VG_NAME/swap_lv1
	swapon /dev/$VG_NAME/swap_lv1
fi

# btrfs
# mount the root partition
mount /dev/vg1/root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
umount /mnt


mount /dev/vg1/var_log /mnt/
btrfs subvolume create /mnt/@
umount /mnt


mount /dev/vg1/var_cache /mnt
btrfs subvolume create /mnt/@
umount /mnt



mount /dev/vg1/var_tmp /mnt
btrfs subvolume create /mnt/@
umount /mnt


# # ext4 did not ever use?
# # may not be needed check dumpe2fs
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

pacstrap -K /mnt base base-devel linux linux-headers linux-docs linux-firmware lvm2 vim git networkmanager refind os-prober efibootmgr iwd cryptsetup amd-ucode intel-ucode iw wireless-regdb fprintd openssh dos2unix pipewire pipewire-audio pipewire-pulse pipewire-alsa wireplumber pipewire-jack lzop btrfs-progs mesa vulkan-radeon libva-mesa-driver realtime-privileges rtkit pipewire-docs bluez bluez-utils openssh acpi python iptables-nft fcron
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


hooks=(
    "/boot/efi/EFI/Linux/arch-linux.efi /boot/vmlinuz-linux"
    "/boot/efi/EFI/Linux/arch-linux-lts.efi /boot/vmlinuz-linux-lts"
    "/boot/efi/EFI/Linux/arch-linux-zen.efi /boot/vmlinuz-linux-zen"
    "/boot/efi/EFI/Linux/arch-linux-rt.efi /boot/vmlinuz-linux-rt"
)

for pair in "${hooks[@]}"; do
    # Split into efi destination and kernel source
    efi_dest=$(echo "$pair" | awk '{print $1}')
    kernel_src=$(echo "$pair" | awk '{print $2}')

    # Create a hash of the pair for unique hook filename
    hash=$(echo -n "$efi_dest $kernel_src" | sha256sum | awk '{print $1}')

    hook_file="/etc/pacman.d/hooks/mkinitcpio-uki-$hash.hook"

    # Generate the hook
    cat <<EOF >"$hook_file"
[Trigger]
Operation=Install
Operation=Upgrade
Type=Package
Target=linux

[Action]
Description = Building UKI for new kernel
When=PostTransaction
Exec=/usr/bin/mkinitcpio -U $efi_dest -k $kernel_src
EOF

    echo "Created hook: $hook_file for EFI dest: $efi_dest and kernel: $kernel_src"
done

# cat <<EOF >/etc/pacman.d/hooks/mkinitcpio-uki.hook
# [Trigger]
# Operation=Install
# Operation=Upgrade
# Type=Package
# Target=linux
#
# [Action]
# Description = Building UKI for new kernel
# When=PostTransaction
# Exec=/usr/bin/mkinitcpio -U /boot/efi/EFI/Linux/arch-linux.efi -k /boot/vmlinuz-linux
# EOF
#
# echo "mkinitcpio-uki hook"

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


# cp wifi_backend.conf wifi_backend.conf_cp
# mkdir -p /mnt/etc/NetworkManager/conf.d/
# mv -f wifi_backend.conf_cp /mnt/etc/NetworkManager/conf.d/wifi_backend.conf
# dos2unix /mnt/etc/NetworkManager/conf.d/wifi_backend.conf


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
"Boot"     "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} ${extra_kern_params}"
"Boot with nomodeset"               "${BOOT_OPTIONS} ${RW_LOGLEVEL_OPTIONS} ${INITRD_OPTIONS} ${MISC_PARAMS} nomodeset ${extra_kern_params}"
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

BOOT_OPTIONS="rd.luks.name=${LUKS_UUID}=cryptroot rd.luks.options=${LUKS_UUID}=allow-discards root=/dev/mapper/vg1-root"
RW_OPTIONS="rw"
MISC_PARAMS="efi_pstore.pstore_disable=0 panic=5"
# EXTRA_PARAMS="${extra_kern_params:-}"
EXTRA_PARAMS="add_efi_memmap preempt=full rcu_nocbs=all rcutree.enable_rcu_lazy=1"

mkdir -p /mnt/etc/kernel
cat > /mnt/etc/kernel/cmdline <<EOF
${BOOT_OPTIONS} ${RW_OPTIONS} ${MISC_PARAMS} ${EXTRA_PARAMS}
EOF


echo "cat /etc/kernel/cmdline"
cat cat /etc/kernel/cmdline
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


