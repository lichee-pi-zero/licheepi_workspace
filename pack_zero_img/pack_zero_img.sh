#!/bin/bash

function echo_log()
{
	echo -e "\033[32m ------------------------------------------ \033[0m"
	echo $1
	echo -e "\033[32m ------------------------------------------\n \033[0m"
}

function echo_error()
{
	echo -e "\033[33m ------------------------------------------ \033[0m"
	echo $1
	echo -e "\033[33m ------------------------------------------\n \033[0m"
}

sudo umount $_PWD/p1 $_PWD/p2 >/dev/null 2>&1
#set -x
set -e

_BOOT="$1"
_ROOTFS="$2"
_DISTRO="$3"
if [ -z $_DISTRO ];then _DISTRO=linux;fi
_PWD=$(pwd)
if [ -n "$_BOOT" -a -n "$_ROOTFS" ]
	then if ([ -s $_BOOT/boot.scr -a -s $_BOOT/u-boot-sunxi-with-spl.bin -a -s $_BOOT/zImage ] && \
                 [ -d  $_ROOTFS/lib/modules/4.10.2-licheepi-zero+ ])
		then
		      echo_log "Checking the files ok!"
		else  echo_error "Can not find boot.scr, zImage, uboot or the modules file!" && exit
	     fi
	else echo_error "No boot or rootfs folder!" && exit
fi

echo_log "Calculating the files's total size..."
_SIZE_BOOT=$(sudo du -s -BM $_BOOT | cut -d 'M' -f 1)
_SIZE_ROOTFS=$(sudo du -s -BM $_ROOTFS | cut -d 'M' -f 1)
_IMG_SIZE=$(($_SIZE_BOOT+$_SIZE_ROOTFS+200))
echo_log "Creating dd img file..."

if [ ! -e $_PWD/lichee_zero-${_DISTRO}.dd ]
	then
	    dd if=/dev/zero of=./lichee_zero-${_DISTRO}.dd bs=1M count=$_IMG_SIZE
fi

if [ $? -ne 0 ]
   then echo_error "getting error in creating dd img!"
   exit
fi

_LOOP_DEV=$(losetup -f)
if [ -z $_LOOP_DEV ]
    then echo_error "can not find a loop device!"
    exit
fi

sudo losetup $_LOOP_DEV ./lichee_zero-${_DISTRO}.dd
if [ $? -ne 0 ]
 	then echo_error "dd img --> $_LOOP_DEV error!"
	sudo losetup -d $_LOOP_DEV >/dev/null 2>&1 && exit
fi

echo_log "creating partitions..."
#blockdev --rereadpt $_LOOP_DEV >/dev/null 2>&1
cat <<EOT |sudo  sfdisk $_LOOP_DEV
1M,16M,c
,,L
EOT
sleep 10
sudo partx -u $_LOOP_DEV
sudo mkfs.vfat ${_LOOP_DEV}p1 ||exit
sudo mkfs.ext4 ${_LOOP_DEV}p2 ||exit
if [ $? -ne 0 ]
	then echo_error "error in creating partitions"
	sudo losetup -d $_LOOP_DEV >/dev/null 2>&1 && exit 
	#sudo partprobe $_LOOP_DEV >/dev/null 2>&1 && exit
fi

echo_log "writing u-boot-sunxi-with-spl to $_LOOP_DEV"
sudo dd if=/dev/zero of=$_LOOP_DEV bs=1K seek=1 count=1023
sudo dd if=$_BOOT/u-boot-sunxi-with-spl.bin of=$_LOOP_DEV bs=1024 seek=8
if [ $? -ne 0 ]
	then echo_error "writing u-boot error!"
	sudo losetup -d $_LOOP_DEV >/dev/null 2>&1 && exit
	#sudo partprobe $_LOOP_DEV >/dev/null 2>&1 && exit
fi

sudo sync
mkdir -p $_PWD/p1 >/dev/null 2>&1
mkdir -p $_PWD/p2 > /dev/null 2>&1
sudo mount ${_LOOP_DEV}p1 $_PWD/p1
sudo mount ${_LOOP_DEV}p2 $_PWD/p2
echo_log "copy boot and rootfs files..."
sudo rm -rf  $_PWD/p1/* && sudo rm -rf  $_PWD/p2/*
sudo cp -f -r $_BOOT/* $_PWD/p1 && sudo cp -a  -f  $_ROOTFS/* $_PWD/p2
if [ $? -ne 0 ]
	then echo_error "copy files error! "
	sudo losetup -d $_LOOP_DEV >/dev/null 2>&1
 	sudo umount ${_LOOP_DEV}p1  ${_LOOP_DEV}p2 >/dev/null 2>&1
	exit
fi
echo_log "Done"
sudo sync
sudo umount $_PWD/p1 $_PWD/p2  && sudo losetup -d $_LOOP_DEV
if [ $? -ne 0 ]
	then echo_error "umount or losetup -d error!!"
	exit
fi

echo_log "The lichee_zero-${_DISTRO}.dd has been created successfully!"
exit

