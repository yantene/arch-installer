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

if [[ $SWAPSIZE -eq 0 ]]; then
  gdisk $DEVICE <<EOS
o
y
n


+128M
ef00
c
efi_system
n



8300
c
2
linux_root
w
y
EOS
else
  gdisk $DEVICE <<EOS
o
y
n


+128M
ef00
c
efi_system
n


+${SWAPSIZE}M
8200
c
2
linux_swap
n



8300
c
3
linux_root
w
y
EOS
fi

## set each device file names

efi_system='/dev/disk/by-partlabel/efi_system'
linux_swap='/dev/disk/by-partlabel/linux_swap'
linux_root='/dev/disk/by-partlabel/linux_root'

while [[ ! -e $efi_system ]] ||
      [[ SWAPSIZE -ne 0 ]] && [[ ! -e $linux_swap ]] ||
      [[ ! -e $linux_root ]]; do
  sleep 0.1
done

## format

mkfs.fat -F32 -n EFI_SYSTEM $efi_system
[[ SWAPSIZE -ne 0 ]] && mkswap -L LINUX_SWAP $linux_swap
[[ SWAPSIZE -ne 0 ]] && swapon $linux_swap
mkfs.btrfs -f -L LINUX_ROOT $linux_root

## set each device mount options

efi_system_mntopts='rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro'
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
mount -o $efi_system_mntopts $efi_system /mnt/boot

# INSTALL

## mirror server
cat > /etc/pacman.d/mirrorlist <<EOS
Server = http://ftp.jaist.ac.jp/pub/Linux/ArchLinux/\$repo/os/\$arch
Server = http://ftp.nara.wide.ad.jp/pub/Linux/archlinux/\$repo/os/\$arch
Server = http://ftp.tsukuba.wide.ad.jp/Linux/archlinux/\$repo/os/\$arch
Server = http://srv2.ftp.ne.jp/Linux/packages/archlinux/\$repo/os/\$arch
Server = http://mirror.premi.st/archlinux/\$repo/os/\$arch
Server = http://ftp.tku.edu.tw/Linux/ArchLinux/\$repo/os/\$arch
Server = http://mirrors.163.com/archlinux/\$repo/os/\$arch
Server = http://ftp.kaist.ac.kr/ArchLinux/\$repo/os/\$arch
Server = http://mirrors.xjtu.edu.cn/archlinux/\$repo/os/\$arch
Server = http://shadow.ind.ntou.edu.tw/archlinux/\$repo/os/\$arch
Server = https://mirrors.xjtu.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server = http://ftp.kddilabs.jp/Linux/packages/archlinux/\$repo/os/\$arch
Server = http://archlinux.cs.nctu.edu.tw/\$repo/os/\$arch
Server = http://mirrors.zju.edu.cn/archlinux/\$repo/os/\$arch
Server = http://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = http://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = http://run.hit.edu.cn/archlinux/\$repo/os/\$arch
Server = http://mirror-fpt-telecom.fpt.net/archlinux/\$repo/os/\$arch
Server = http://mirrors.cug.edu.cn/archlinux/\$repo/os/\$arch
Server = http://ftp.yzu.edu.tw/Linux/archlinux/\$repo/os/\$arch
Server = http://mirrors.neusoft.edu.cn/archlinux/\$repo/os/\$arch
Server = http://f.archlinuxvn.org/archlinux/\$repo/os/\$arch
Server = http://mirrors.cqu.edu.cn/archlinux/\$repo/os/\$arch
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
  dialog \
  linux-firmware \
  wpa_supplicant

# SETUP

CHROOT="arch-chroot /mnt"

## edit fstab

cat > /mnt/etc/fstab <<EOS
PARTLABEL='linux_root'  /     btrfs $linux_root_mntopts 0 0
PARTLABEL='efi_system'  /boot vfat  $efi_system_mntopts 0 2
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
$CHROOT pacman --noconfirm -S grub efibootmgr
$CHROOT grub-install --recheck --target=i386-efi --efi-directory=/boot --bootloader-id=grub
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
