#!/bin/bash


TMPDIR=$(mktemp --tmpdir="/tmp" -d "fipaak_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
git clone https://aur.archlinux.org/freeipa.git $TMPDIR
gpg --import $TMPDIR/keys/pgp/*asc
rm -fr $TMPDIR
