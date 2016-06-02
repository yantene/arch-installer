#!/bin/sh

# INPUT PARAMETERS

read -p  'device (/dev/sda): ' DEVICE
[[ -z $DEVICE ]] && DEVICE='/dev/sda'

read -p  'hostname (YanteneLaptop): ' HOSTNAME
[[ -z $HOSTNAME ]] && HOSTNAME='YanteneLaptop'

read -p  'username (yantene): ' USERNAME
[[ -z $USERNAME ]] && USERNAME='yantene'

read -sp 'password: ' PASSWORD

set -ux

# SETUP STORAGE

## partitioning

gdisk $DEVICE <<EOS
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
EOS

## set each device file names

efi_system_partition='/dev/disk/by-partlabel/efi_system_partition'
linux_btrfs_partition='/dev/disk/by-partlabel/linux_btrfs_partition'

## format

mkfs.vfat -F32 -n EFI_SYSTEM $efi_system_partition
mkfs.btrfs -L LINUX_BTRFS -f $linux_btrfs_partition

## create btrfs subvolume

mount $linux_btrfs_partition /mnt
cd /mnt
btrfs subvolume create root
rootvol_id=`btrfs subvol list -p . | cut -d' ' -f2`
btrfs subvolume create root/home
btrfs subvolume set-default $rootvol_id .
btrfs subvolume create snapshots
cd -
umount /mnt

## mount

btrfs_mntopts='noatime,discard,ssd,autodefrag,compress=lzo,space_cache'
mount -o $btrfs_mntopts $linux_btrfs_partition /mnt
mkdir /mnt/boot
mount $efi_system_partition /mnt/boot

# INSTALL

## mirror server
cat > /etc/pacman.d/mirrorlist <<EOS
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
EOS

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

## edit fstab

cat > /mnt/etc/fstab <<EOS
PARTLABEL='linux_btrfs_partition' /     btrfs rw,$btrfs_mntopts,subvol=/root                                                                       0 0
PARTLABEL='efi_system_partition'  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro 0 2
EOS

## hostname

echo $HOSTNAME > /mnt/etc/hostname

## locale

cat > /mnt/etc/locale.gen <<EOS
ja_JP.UTF-8 UTF-8
en_US.UTF-8 UTF-8
EOS
echo 'LANG=ja_JP.UTF-8' > /mnt/etc/locale.conf
$CHROOT locale-gen
echo -e 'KEYMAP=us\nFONT=Lat2-Terminus16' > /mnt/etc/vconsole.conf
$CHROOT ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
$CHROOT hwclock --systohc --utc

## boot

$CHROOT mkinitcpio -p linux
$CHROOT bootctl --path=/boot install
cat > /mnt/boot/loader/entries/arch.conf <<EOS
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTLABEL=linux_btrfs_partition rw
EOS
cat > /mnt/boot/loader/loader.conf <<EOS
default arch
timeout 0
EOS

## pacman settings

### multilib

if [ `uname -m` = 'x86_64' ]; then
cat >> /mnt/etc/pacman.conf <<EOS
[multilib]
Include = /etc/pacman.d/mirrorlist
EOS
pacman -Syy
fi

### yaourt

cat >> /mnt/etc/pacman.conf <<EOS
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch
EOS
$CHROOT pacman -Sy --noconfirm archlinuxfr/yaourt

## root settings

$CHROOT passwd <<EOS
$PASSWORD
$PASSWORD
EOS
$CHROOT chsh <<EOS
/bin/zsh
EOS

## user settings

$CHROOT useradd -m -g users -G wheel,video,audio -s /bin/zsh $USERNAME
$CHROOT passwd $USERNAME <<EOS
$PASSWORD
$PASSWORD
EOS
$CHROOT sed -i 's/^#\s%wheel\s*ALL=(ALL)\s*ALL$/%wheel\tALL=(ALL)\tALL/g' /etc/sudoers

## create btrfs snapshot

umount -R /mnt
mount -o $btrfs_mntopts $linux_btrfs_partition /mnt
ptime=`date +'%s'`
btrfs subvolume snapshot /mnt/root      /mnt/snapshots/$ptime-root
btrfs subvolume snapshot /mnt/root/home /mnt/snapshots/$ptime-home
umount /mnt

set +x
