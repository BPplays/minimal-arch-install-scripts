#!/bin/bash


TMPDIR=$(mktemp -d)
git clone https://aur.archlinux.org/freeipa.git $TMPDIR
gpg --import $TMPDIR/keys/pgp/*asc
rm -fr $TMPDIR
