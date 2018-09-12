#!/bin/bash
 
# Creates a bootable ISO from Ubuntu PXE images.
# Also adds a run script to the OEM partition and converts the ISO so it can boot from USB media.
 
set -e
 
# Default configurations
SSH_PUBKEY_PATH=~/.ssh/id_rsa.pub
 
# Initialze variables
 
SSH_PUBKEY=`cat ${SSH_PUBKEY_PATH}`
 
bindir=`cd $(dirname $0) && pwd`
 
echo "-----> Initialize working directory"
 
mkdir -p iso/boot/grub
mkdir -p iso/ubuntu

if [ ! -e iso/ubuntu/vmlinuz ]; then
	cp $bindir/ipa_ubuntu.vmlinuz iso/ubuntu/vmlinuz
fi
 
if [ ! -e iso/ubuntu/initramfs ]; then
        cp $bindir/ipa_ubuntu.initramfs iso/ubuntu/initramfs
fi

if [ ! -e iso/boot/gurb/grub.cfg ]; then
        cp $bindir/grubrescue.cfg iso/boot/grub/grub.cfg
fi

echo "-----> Make ISO file"
cd iso
grub-mkrescue -o $bindir/ipa_ubuntu_grubrescue.iso .
echo "-----> Cleanup"
cd $bindir
rm -rf iso/
 
echo "-----> Finished"
