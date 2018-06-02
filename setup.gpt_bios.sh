#!/bin/sh

# INPUT PARAMETERS

read -p  'device (/dev/sda): ' DEVICE
[[ -z $DEVICE ]] && DEVICE='/dev/sda'

read -p  'hostname (YanteneLaptop): ' HOSTNAME
[[ -z $HOSTNAME ]] && HOSTNAME='YanteneLaptop'

read -p  'username (yantene): ' USERNAME
[[ -z $USERNAME ]] && USERNAME='yantene'

read -p  'swap size (0[MB]): ' SWAPSIZE
[[ -z $SWAPSIZE ]] && SWAPSIZE='0'

while [[ -z $PASSWORD ]]; do
  read -sp 'password: ' PASSWORD
  echo
done

set -eux

# SETUP STORAGE

## partitioning

sgdisk -Z $DEVICE
if [[ $SWAPSIZE -eq 0 ]]; then
  sgdisk -n '1::+2M' $DEVICE
  sgdisk -t '1:ef02' $DEVICE
  sgdisk -c '1:bios_boot' $DEVICE

  sgdisk -n '2::' $DEVICE
  sgdisk -t '2:8300' $DEVICE
  sgdisk -c '2:linux_root' $DEVICE
else
  sgdisk -n '1::+2M' $DEVICE
  sgdisk -t '1:ef02' $DEVICE
  sgdisk -c '1:bios_boot' $DEVICE

  sgdisk -n "2::+${SWAPSIZE}M" $DEVICE
  sgdisk -t '2:8200' $DEVICE
  sgdisk -c '2:linux_swap' $DEVICE

  sgdisk -n '3::' $DEVICE
  sgdisk -t '3:8300' $DEVICE
  sgdisk -c '3:linux_root' $DEVICE
fi

## set each device file names

bios_boot='/dev/disk/by-partlabel/bios_boot'
linux_swap='/dev/disk/by-partlabel/linux_swap'
linux_root='/dev/disk/by-partlabel/linux_root'

sleep 10 # XXX

## format

[[ $SWAPSIZE -ne 0 ]] && mkswap -L LINUX_SWAP $linux_swap
[[ $SWAPSIZE -ne 0 ]] && swapon $linux_swap
mkfs.btrfs -f -L LINUX_ROOT $linux_root

## set device mount options

linux_root_mntopts='rw,noatime,discard,ssd,autodefrag,compress=lzo,space_cache'

## create btrfs subvolume

mount -o $linux_root_mntopts $linux_root /mnt
cd /mnt
btrfs subvolume create root
btrfs subvolume set-default `btrfs subvol list -p . | cut -d' ' -f2` .
btrfs subvolume create root/home
btrfs subvolume create snapshots
cd ~
umount /mnt

## mount

mount -o $linux_root_mntopts $linux_root /mnt
mkdir /mnt/boot

# INSTALL

## mirror server
cp -f `dirname $0`/res/mirrorlist /etc/pacman.d/mirrorlist

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
PARTLABEL='linux_root'  /     btrfs $linux_root_mntopts 0 0
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
$CHROOT ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
$CHROOT hwclock --systohc --utc

## boot

$CHROOT mkinitcpio -p linux
$CHROOT pacman --noconfirm -S grub
$CHROOT grub-install --recheck --target=i386-pc $DEVICE
$CHROOT grub-mkconfig -o /boot/grub/grub.cfg

## pacman settings

### multilib

if [ `uname -m` = 'x86_64' ]; then
cat >> /mnt/etc/pacman.conf <<EOS
[multilib]
Include = /etc/pacman.d/mirrorlist
EOS
$CHROOT pacman -Syy
fi

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
mount -o $linux_root_mntopts,subvol=/ $linux_root /mnt
ptime=`date +'%s'`
btrfs subvolume snapshot /mnt/root      /mnt/snapshots/${ptime}-root
btrfs subvolume snapshot /mnt/root/home /mnt/snapshots/${ptime}-home
umount /mnt

set +x
