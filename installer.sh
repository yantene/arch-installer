#!/bin/sh

# INPUT PARAMETERS

read -p  "hostname: " HOSTNAME
read -p  "username: " USERNAME
read -sp "password: " PASSWORD

set -ux

# SETUP STORAGE

## partitioning

gdisk /dev/sda <<EOF
o
y
n


+128M
ef00
c
efi_system_partition
n



8300
c
2
linux_btrfs_partition
w
y
EOF

## format

mkfs.fat -F32 -n EFI_SYSTEM /dev/sda1
mkfs.btrfs -L LINUX_BTRFS -f /dev/sda2

## create btrfs subvolume

mount /dev/sda2 /mnt
cd /mnt
btrfs subvolume create root
rootvol_id=`btrfs subvol list -p . | cut -d' ' -f2`
btrfs subvolume create root/home
btrfs subvolume set-default $rootvol_id .
cd -
umount /mnt

## mount

btrfs_mntopts='noatime,discard,ssd,autodefrag,compress=lzo,space_cache'
mount -o $btrfs_mntopts /dev/sda2 /mnt
mkdir /mnt/home
mount -o $btrfs_mntopts /dev/sda2 -osubvol=home /mnt/home
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# INSTALL

## mirror server
cat > /etc/pacman.d/mirrorlist <<EOF
Server = http://ftp.jaist.ac.jp/pub/Linux/ArchLinux/\$repo/os/\$arch
Server = http://ftp.tsukuba.wide.ad.jp/Linux/archlinux/\$repo/os/\$arch
Server = http://archlinux.cs.nctu.edu.tw/\$repo/os/\$arch
Server = http://ftp.tku.edu.tw/Linux/ArchLinux/\$repo/os/\$arch
Server = http://shadow.ind.ntou.edu.tw/archlinux/\$repo/os/\$arch
Server = http://mirrors.cdndepo.com/archlinux/\$repo/os/\$arch
Server = http://mirror.pregi.net/pub/Linux/archlinux/\$repo/os/\$arch
Server = http://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = http://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server = http://ftp.yzu.edu.tw/Linux/archlinux/\$repo/os/\$arch
EOF

## install

pacstrap /mnt \
  base \
  base-devel \
  dosfstools \
  btrfs-progs \
  lzo \
  zsh \
  neovim \
  openssh \
  wpa_supplicant

# SETUP

CHROOT="arch-chroot /mnt"

## generate fstab

genfstab -L -p /mnt >> /mnt/etc/fstab

## hostname

echo $HOSTNAME > /mnt/etc/hostname

## locale

$CHROOT sed -i -e 's/#ja_JP.UTF-8/ja_JP.UTF-8/' /etc/locale.gen
$CHROOT sed -i -e 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
echo 'LANG=ja_JP.UTF-8' > /mnt/etc/locale.conf
$CHROOT locale-gen
echo -e 'KEYMAP=us\nFONT=Lat2-Terminus16' > /mnt/etc/vconsole.conf
$CHROOT ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
$CHROOT hwclock --systohc --utc

## boot

$CHROOT mkinitcpio -p linux
$CHROOT bootctl --path=/boot install
cat > /mnt/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=/dev/sda2 rw
EOF
cat > /mnt/boot/loader/loader.conf <<EOF
default arch
timeout 0
EOF

## yaourt

cat >> /mnt/etc/pacman.conf <<EOF
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch
EOF
$CHROOT pacman -Sy --noconfirm archlinuxfr/yaourt

## root settings

$CHROOT passwd <<EOF
$PASSWORD
$PASSWORD
EOF
$CHROOT chsh <<EOF
/bin/zsh
EOF

## user settings

$CHROOT useradd -m -g users -G wheel,video,audio -s /bin/zsh $USERNAME
$CHROOT passwd $USERNAME <<EOF
$PASSWORD
$PASSWORD
EOF
$CHROOT sed -i 's/^#\s%wheel\s*ALL=(ALL)\s*ALL$/%wheel\tALL=(ALL)\tALL/g' /etc/sudoers

## sshd の有効化

$CHROOT systemctl enable sshd

set +x
