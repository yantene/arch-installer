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

## get each device file names

parts=(`fdisk -l $DEVICE | tail -n 2 | cut -d' ' -f1`)
part1=${parts[0]}
part2=${parts[1]}

## format

mkfs.vfat -F32 -n EFI_SYSTEM $part1
mkfs.btrfs -L LINUX_BTRFS -f $part2

## create btrfs subvolume

mount $part2 /mnt
cd /mnt
btrfs subvolume create root
rootvol_id=`btrfs subvol list -p . | cut -d' ' -f2`
btrfs subvolume create root/home
btrfs subvolume set-default $rootvol_id .
cd -
umount /mnt

## mount

btrfs_mntopts='noatime,discard,ssd,autodefrag,compress=lzo,space_cache'
mount -o $btrfs_mntopts $part2 /mnt
mkdir /mnt/boot
mount $part1 /mnt/boot

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
LABEL=LINUX_BTRFS /     btrfs rw,noatime,compress=lzo,ssd,discard,space_cache,autodefrag,subvolid=257,subvol=/root,subvol=root     0 0
LABEL=EFI_SYSTEM  /boot vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro 0 2
EOS

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

set +x
