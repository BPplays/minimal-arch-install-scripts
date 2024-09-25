#!/bin/bash


sudo pacman -Syu --noconfirm


TMPDIR=$(mktemp -d)
git clone https://aur.archlinux.org/freeipa.git $TMPDIR
gpg --import $TMPDIR/keys/pgp/*asc
rm -fr $TMPDIR
yay -Syu

yay -Sua --sudoloop --noconfirm --aur libsepol
yay -Sua --sudoloop --noconfirm --aur freeipa-client


while true; do
	# Ask the user if they want to cancel the FreeIPA installation
	read -p "Do you want to install FreeIPA client using ipa-client-install? (y/N): " install_ipa

	install_ipa=${install_ipa:-N}  # Default to 'Y' if no input
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
	cmd="sudo ipa-client-install $mkhomedir $forcejoin"
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

sudo tee -a /etc/ssh/sshd_config <<EOF
UsePAM yes
AuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys
AuthorizedKeysCommandUser nobody
GSSAPIAuthentication yes
KerberosAuthentication no
ChallengeResponseAuthentication yes
EOF

sudo systemctl start sshd
sudo systemctl enable sshd
sudo systemctl restart sshd

