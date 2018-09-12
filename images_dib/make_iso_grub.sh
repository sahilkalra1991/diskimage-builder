#!/bin/bash
 
# Creates a bootable ISO from Ubuntu PXE images.
# Also adds a run script to the OEM partition and converts the ISO so it can boot from USB media.
 
set -e
 
# Default configurations
bindir=`cd $(dirname $0) && pwd`
bootdir=iso/ubuntu
 
echo "-----> Initialize working directory"
 
mkdir -p iso/boot/grub
mkdir -p $bootdir

if [ ! -e $bootdir/vmlinuz ]; then
	cp $bindir/ipa_ubuntu.vmlinuz $bootdir/vmlinuz
fi
 
if [ ! -e $bootdir/initramfs ]; then
        cp $bindir/ipa_ubuntu.initramfs $bootdir/initramfs
fi

echo "-----> Make menu.lst file"
cat<<EOF > iso/boot/grub/menu.lst
#
# Boot menu configuration file
#
# By default, boot the first entry.
default 0
# Boot automatically after 5 secs.
timeout 5

title  IPA-Ubuntu-Pike
kernel /ubuntu/vmlinuz
initrd /ubuntu/initramfs
EOF

echo "-----> Copy ElTorio"
cp /usr/lib/grub/x86_64-pc/stage2_eltorito iso/boot/grub

echo "-----> Make ISO file"
cd iso
mkisofs -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o $bindir/ipa_ubuntu_grub.iso .
echo "-----> Cleanup"
cd $bindir
rm -rf iso/
 
echo "-----> Finished"
