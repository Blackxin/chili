#!/bin/bash

chili-image()
{
	# https://www.qemu.org/2021/08/22/fuse-blkexport/
	qemu-img create -f raw foo.img 20G
	parted -s foo.img 		\
    	'mklabel msdos' 		\
    	'mkpart primary ext4 2048s 100%'
	qemu-img convert -p -f raw -O qcow2 foo.img foo.qcow2 && rm foo.img
 	file foo.qcow2
	sudo kpartx -l foo.qcow2

#	qemu-storage-daemon \
#    --blockdev node-name=prot-node,driver=file,filename=foo.qcow2 \
#    --blockdev node-name=fmt-node,driver=qcow2,file=prot-node \
#    --export \
#    type=fuse,id=exp0,node-name=fmt-node,mountpoint=foo.qcow2,writable=on \
#    &
	qemu-storage-daemon \
  		--blockdev node-name=prot-node,driver=file,filename=foo.qcow2 \
  		--blockdev node-name=fmt-node,driver=qcow2,file=prot-node \
  		--export \
  		type=fuse,id=exp0,node-name=fmt-node,mountpoint=mount-point,writable=on

	file foo.qcow2
	sudo kpartx -av foo.qcow2
	fdisk -l foo.qcow2
	cfdisk foo.qcow2
}

chili-mapdevice()
{
	#sudo mknod -m 0777 /dev/sr0 b 7 10
	#sudo mknod -m 0777 /dev/sr0 b 7 20
	#losetup -P /dev/sr0 $1
	kpartx -av $1 # kpartx -av file.img
}

if [[ $# -eq 0 ]]; then
	printf "Usage: $0 /dev/sdX\n"
	exit 1;
fi

#sd=$1
#parted --script $sd -- 															\
#   mklabel gpt             													\
#   mkpart primary fat32      1MiB   100MiB set 1 bios on name 1 BIOS  \
#   mkpart primary fat32      100MiB 200MiB set 2 esp  on name 2 EFI   \
#   mkpart primary linux-swap 200MiB 2GB                  name 3 SWAP  \
#   mkpart primary ext4       2GB 100%                    name 4 ROOT  \
#   align-check optimal 1
#parted --script $sd -- print

sd=$1
parted --script $sd -- 																\
   mklabel gpt             					 									\
   mkpart primary fat32      1MiB 2MiB set 1 bios on name 1 BIOS  	\
   mkpart primary fat32      2MiB 50MiB set 2 esp  on name 2 EFI   	\
   mkpart primary ext4       50MiB 100%                name 3 ROOT  	\
   align-check optimal 1
parted --script $sd -- print
