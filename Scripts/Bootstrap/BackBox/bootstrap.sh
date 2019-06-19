#!/usr/bin/env bash

#Bootstrap the system
rm -rf $2
mkdir $2
if [ "$1" = "i386" ] || [ "$1" = "amd64" ] ; then
  debootstrap --no-check-gpg --arch=$1 --variant=minbase --include=systemd,libsystemd0,wget,ca-certificates,udisks2,gvfs xenial $1 http://archive.ubuntu.com/ubuntu
else  
  qemu-debootstrap --no-check-gpg --arch=$1 --variant=minbase --include=systemd,libsystemd0,wget,ca-certificates,udisks2,gvfs xenial $1 http://ports.ubuntu.com/ubuntu-ports
fi

#Reduce size
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
 LC_ALL=C LANGUAGE=C LANG=C chroot $2 apt-get clean

#Fix permission on dev machine only for easy packing
chmod 777 -R $2

#This step is also needed for BackBox as it is based on Ubuntu Xenial
touch $2/root/.hushlogin

#This step is only needed for BackBox to import BackBox repo key
chroot $2 apt-key adv --keyserver keyserver.ubuntu.com --recv-key 680E1A5A78A7ABE1

#Setup DNS
echo "127.0.0.1 localhost" > $2/etc/hosts
echo "nameserver 8.8.8.8" > $2/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $2/etc/resolv.conf

#sources.list setup
rm $2/etc/apt/sources.list
if [ "$1" = "i386" ] || [ "$1" = "amd64" ] ; then
  echo "deb http://archive.ubuntu.com/ubuntu xenial main restricted universe multiverse" >> $2/etc/apt/sources.list
  echo "deb-src http://archive.ubuntu.com/ubuntu xenial main restricted universe multiverse" >> $2/etc/apt/sources.list
  echo "" >> $2/etc/apt/sources.list
  echo "deb http://ppa.launchpad.net/backbox/five/ubuntu xenial main" >> $2/etc/apt/sources.list
  echo "deb-src http://ppa.launchpad.net/backbox/five/ubuntu xenial main" >> $2/etc/apt/sources.list
else  
  echo "deb http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe multiverse" >> $2/etc/apt/sources.list
  echo "deb-src http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe multiverse" >> $2/etc/apt/sources.list
  echo "" >> $2/etc/apt/sources.list
  echo "deb http://ppa.launchpad.net/backbox/five/ubuntu xenial main" >> $2/etc/apt/sources.list
  echo "deb-src http://ppa.launchpad.net/backbox/five/ubuntu xenial main" >> $2/etc/apt/sources.list
fi

#tar the rootfs
cd $2
rm -rf ../backbox-rootfs-$1.tar.xz
rm -rf dev/*
XZ_OPT=-9 tar -cJvf ../backbox-rootfs-$1.tar.xz ./*
