#!/bin/bash
 
# Creates a bootable ISO from CoreOS' PXE images.
# Also adds a run script to the OEM partition and converts the ISO so it can boot from USB media.
# Based heavily off https://github.com/nyarla/coreos-live-iso - Thanks Naoki!
 
set -e
 
# Default configurations
SYSLINUX_VERSION="6.02"
COREOS_VERSION="master"
BOOT_ENV="bios"
SSH_PUBKEY_PATH=~/.ssh/id_rsa.pub
 
# Initialze variables
SYSLINUX_BASE_URL="https://www.kernel.org/pub/linux/utils/boot/syslinux"
SYSLINUX_BASENAME="syslinux-$SYSLINUX_VERSION"
SYSLINUX_URL="${SYSLINUX_BASE_URL}/${SYSLINUX_BASENAME}.tar.gz"
 
#COREOS_BASE_URL="http://storage.core-os.net/coreos/amd64-generic"
#COREOS_KERN_BASENAME="coreos_production_pxe.vmlinuz"
#COREOS_INITRD_BASENAME="coreos_production_pxe_image.cpio.gz"
#COREOS_KERN_URL="${COREOS_BASE_URL}/${COREOS_VERSION}/${COREOS_KERN_BASENAME}"
#COREOS_INITRD_URL="${COREOS_BASE_URL}/${COREOS_VERSION}/${COREOS_INITRD_BASENAME}"
 
SSH_PUBKEY=`cat ${SSH_PUBKEY_PATH}`
 
bindir=`cd $(dirname $0) && pwd`
workdir=$bindir/work
 
echo "-----> Initialize working directory"
if [ ! -d $workdir ];then
    mkdir -p $workdir
fi;
 
cd $workdir
 
mkdir -p iso/ubuntu
mkdir -p iso/syslinux
mkdir -p iso/isolinux
 
echo "-----> Download CoreOS's kernel"
if [ ! -e iso/ubuntu/vmlinuz ]; then
  cp $bindir/ipa_ubuntu.vmlinuz iso/ubuntu/vmlinuz
fi
 
echo "-----> Download CoreOS's initrd"
if [ ! -e iso/ubuntu/ipa_ubuntu.initramfs ]; then
  cp $bindir/ipa_ubuntu.initramfs iso/ubuntu/initramfs
fi
cd iso/ubuntu
mkdir -p usr/share/oem
cat<<EOF > usr/share/oem/run
#!/bin/sh
 
# Place your OEM run commands here...
 
EOF
#chmod +x usr/share/oem/run
#gzip -d cpio.gz
#find usr | cpio -o -A -H newc -O cpio
#gzip cpio
rm -rf usr/share/oem
cd $workdir
 
echo "-----> Download syslinux and copy to iso directory"
if [ ! -e ${SYSLINUX_BASENAME} ]; then
  curl -O $SYSLINUX_URL
fi
tar zxf ${SYSLINUX_BASENAME}.tar.gz
 
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/com32/chain/chain.c32 iso/syslinux/
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/com32/lib/libcom32.c32 iso/syslinux/
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/com32/libutil/libutil.c32 iso/syslinux/
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/memdisk/memdisk iso/syslinux/
 
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/core/isolinux.bin iso/isolinux/
cp ${SYSLINUX_BASENAME}/${BOOT_ENV}/com32/elflink/ldlinux/ldlinux.c32 iso/isolinux/
 
echo "-----> Make isolinux.cfg file"
cat<<EOF > iso/isolinux/isolinux.cfg
INCLUDE /syslinux/syslinux.cfg
EOF
 
echo "-----> Make syslinux.cfg file"
cat<<EOF > iso/syslinux/syslinux.cfg
default ubuntu
prompt 1
timeout 15
 
label ubuntu
  kernel /ubuntu/vmlinuz
  append initrd=/ubuntu/initramfs root=squashfs: state=tmpfs: sshkey="${SSH_PUBKEY}"
EOF
 
echo "-----> Make ISO file"
cd iso
mkisofs -v -l -r -J -o ${bindir}/ipa_ubuntu.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table .
${workdir}/${SYSLINUX_BASENAME}/bios/utils/isohybrid ${bindir}/ipa_ubuntu.iso
echo "-----> Cleanup"
cd $bindir
rm -rf $workdir
 
echo "-----> Finished"

