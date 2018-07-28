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
  read -sp 'password: ' PASSWORD1
  echo
  read -sp 'password (confirm): ' PASSWORD2
  echo
  [[ $PASSWORD1 = $PASSWORD2 ]] && PASSWORD=PASSWORD1
done

set -eux

# SETUP STORAGE

## partitioning

sgdisk -Z $DEVICE

sgdisk -n '1::+512M' $DEVICE
if [[ -e /sys/firmware/efi/efivars ]]; then
  sgdisk -t '1:ef00' $DEVICE
  sgdisk -c '1:efi_system' $DEVICE
else
  sgdisk -t '1:ef02' $DEVICE
  sgdisk -c '1:bios_boot' $DEVICE
fi

if [[ $SWAPSIZE -eq 0 ]]; then
  sgdisk -n '2::' $DEVICE
  sgdisk -t '2:8300' $DEVICE
  sgdisk -c '2:linux_root' $DEVICE
else
  sgdisk -n "2::+${SWAPSIZE}M" $DEVICE
  sgdisk -t '2:8200' $DEVICE
  sgdisk -c '2:linux_swap' $DEVICE

  sgdisk -n '3::' $DEVICE
  sgdisk -t '3:8300' $DEVICE
  sgdisk -c '3:linux_root' $DEVICE
fi

## set each device file names

efi_system='/dev/disk/by-partlabel/efi_system'
linux_swap='/dev/disk/by-partlabel/linux_swap'
linux_root='/dev/disk/by-partlabel/linux_root'

sleep 10 # XXX

## format

[[ -e /sys/firmware/efi/efivars ]] && mkfs.fat -F32 -n EFI_SYSTEM $efi_system
[[ $SWAPSIZE -ne 0 ]] && mkswap -L LINUX_SWAP $linux_swap
[[ $SWAPSIZE -ne 0 ]] && swapon $linux_swap
mkfs.btrfs -f -L LINUX_ROOT $linux_root

## set each device mount options

efi_system_mntopts='rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro'
linux_root_mntopts='rw,noatime,discard,ssd,autodefrag,compress=lzo,space_cache'

## create btrfs subvolume


mount -o $linux_root_mntopts $linux_root /mnt
(
  cd /mnt
  btrfs subvolume create root
  btrfs subvolume set-default `btrfs subvol list -p . | cut -d' ' -f2` .
  btrfs subvolume create root/home
  btrfs subvolume create snapshots
)
umount /mnt

## mount

mount -o $linux_root_mntopts $linux_root /mnt
mkdir /mnt/boot
[[ -e /sys/firmware/efi/efivars ]] && mount -o $efi_system_mntopts $efi_system /mnt/boot

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
  git \
  go \
  zsh

# SETUP

CHROOT="arch-chroot /mnt"

## edit fstab

echo "PARTLABEL='linux_root'  /     btrfs $linux_root_mntopts 0 0" > /mnt/etc/fstab
if [[ -e /sys/firmware/efi/efivars ]]; then
  echo "PARTLABEL='efi_system'  /boot vfat  $efi_system_mntopts 0 2" >> /mnt/etc/fstab
fi

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
if [[ -e /sys/firmware/efi/efivars ]]; then
  $CHROOT bootctl --path=/boot install
  cat > /mnt/boot/loader/entries/arch.conf <<EOS
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTLABEL=linux_root rw
EOS
  cat > /mnt/boot/loader/loader.conf <<EOS
default arch
timeout 0
EOS
else
  $CHROOT pacman --noconfirm -S grub
  $CHROOT grub-install --recheck --target=i386-pc $DEVICE
  $CHROOT grub-mkconfig -o /boot/grub/grub.cfg
fi

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

## install yay

$CHROOT bash -c "
  cd \`sudo -u $USERNAME mktemp -d\`;
  curl -L https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz | sudo -u $USERNAME tar zxf - --strip=1;
  sudo -u $USERNAME makepkg --noconfirm;
  pacman -U --noconfirm ./yay*.pkg.tar.xz
"

## install packages

$CHROOT bash -c "
  echo '$USERNAME ALL=(root) NOPASSWD: ALL' >> /etc/sudoers
  sudo -u $USERNAME yay --noconfirm -S $(sed 's/#.*$//g' `dirname $0`/res/packages | tr '\n' ' ')
  sed -i -e '\$d' /etc/sudoers
"

## create btrfs snapshot

umount -R /mnt
mount -o $linux_root_mntopts,subvol=/ $linux_root /mnt
ptime=`date +'%s'`
btrfs subvolume snapshot /mnt/root      /mnt/snapshots/${ptime}-root
btrfs subvolume snapshot /mnt/root/home /mnt/snapshots/${ptime}-home
umount /mnt

set +x
