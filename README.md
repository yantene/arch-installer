# Arch installer

EFI 環境および GPT BIOS 環境に Arch Linux をインストールするスクリプトです。
筆者が Arch Linux の環境構築する際に使用しているスクリプトを公開しているものです。

EFI 環境は SONY VAIO Pro (SVP1321A1J)、
BIOS 環境は SONY VAIO T (SVT1311AJ) で検証しました。
その他、職場の環境や Virtualbox、QEMU などでも動作を確認しています。

なお、本スクリプトの使用は自己責任でお願いいたします。

## 本スクリプトの特徴

- EFI 環境、BIOS 環境ともに GPT でパーティショニングします。
  - EFI 環境のブートローダは systemd-boot です。
  - BIOS 環境のブートローダは GRUB です。
- ファイルシステムは btrfs を利用します。
  - インストール直後の環境は自動でスナップショットを撮ります。
- AUR ヘルパーとして [yay](/Jguer/yay) をインストールします。

## 使い方

まず、Arch のインストールメディアをインストールしたい対象環境でブートします。

次に、インターネット接続を行います。
環境に合わせて `wifi-menu` なり `dhcpcd` なりを叩きましょう。

最後に、本リポジトリのシェルスクリプトをダウンロードします。
インストールメディアに `git` が入っていないので、
`curl` を使うのが一番手軽な方法かと思います。

```bash
curl -L git.io/yai.tgz | tar zxf -
```

次に `arch-installer-master/res/mirrorlist` を編集して、
使用したいミラーサーバを指定してください。
デフォルトでは日本周辺のミラーサーバを指定してあります。

同様に、 `arch-installer-master/res/packages` を編集して、
デフォルトでインストールしたいパッケージを追加してください。
AUR のパッケージも指定することができます。

そして`arch-installer-master/setup.sh`を実行し、
指示に従って以下の項目を入力します。

- **インストール先デバイス** (デフォルト値: /dev/sda)
- **ホスト名** (デフォルト値: YanteneLaptop)
- **ユーザ名** (デフォルト値: yantene)
- **パスワード** (root と上記ユーザ名のユーザは同じパスワードとなります)
- **スワップ領域のサイズ** (デフォルト値: 0)

後はよしなにインストールされます。

再起動し、インストール先デバイスからブートしてください。

## インストール後

筆者は、CLI 周りの環境は、
[yantene/config: dotfiles and great buddies](/yantene/config)
を `$HOME/.config` に `git clone` して整えています。

また、GUI 周りであったり、
プリンタに関するまとめであったりを
本リポジトリの `doc/` 下に配置しています。
いずれ整理するつもりで、
現在非常に雑然としていますが、参考にしてください。

## baytrail tablet について

boot に関する箇所を、
以下に置換すればインストール可能です。

```bash
$CHROOT mkinitcpio -p linux
$CHROOT pacman --noconfirm -S grub efibootmgr
$CHROOT grub-install --recheck --target=i386-efi --efi-directory=/boot --bootloader-id=grub
$CHROOT grub-mkconfig -o /boot/grub/grub.cfg
```

## 参考文献

インストールスクリプトの書き方には以下を参考にしました。

- [archlinux-autonistaller](/tukiyo/archlinux-autonistaller)
