# Arch installer

EFI 環境および GPT BIOS 環境に Arch Linux をインストールするスクリプトです。
筆者が個人のラップトップや職場のデスクトップ、
仮想マシン上などで Arch Linux の環境構築する際に使用しているスクリプトを公開しているものです。

当然ですが、本スクリプトの使用は自己責任でお願いいたします。

## 本スクリプトの特徴

- EFI 環境、BIOS 環境ともに GPT でパーティショニングします。
  - EFI 環境のブートローダは systemd-boot です。
  - BIOS 環境のブートローダは GRUB です。
- ファイルシステムは btrfs を利用します。
  - ストレージは SSD を想定しています。
  - snapper でスナップショットを撮ることを想定しています。
- AUR ヘルパーとして [yay](/Jguer/yay) をインストールします。

## 使い方

まず、Arch のインストールメディアをインストールしたい対象環境でブートします。

次に、インターネット接続を行います。
環境に合わせて `wifi-menu` なり `dhcpcd` なりを叩きましょう。

最後に、本リポジトリのシェルスクリプトをダウンロードします。
インストールメディアに `git` が入っていないので、
`curl` を使うのが一番手軽な方法かと思います。

```bash
curl -L git.io/yai.tgz | tar zxf - # git.io/yai_dev.tgz で `dev` ブランチも使用可能
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
- **ホスト名** (デフォルト値: yantene-laptop)
- **ユーザ名** (デフォルト値: yantene)
- **パスワード** (root と上記ユーザ名のユーザは同じパスワードとなります)
- **スワップ領域のサイズ** (デフォルト値: 0)

後はよしなにインストールされます。

再起動し、インストール先デバイスからブートしてください。

## インストール後

### SSD の trim 設定

```shell-session
sudo systemctl enable --now fstrim.timer
```

cf. [ソリッドステートドライブ - ArchWiki](https://wiki.archlinux.jp/index.php/%E3%82%BD%E3%83%AA%E3%83%83%E3%83%89%E3%82%B9%E3%83%86%E3%83%BC%E3%83%88%E3%83%89%E3%83%A9%E3%82%A4%E3%83%96#fstrim_.E3.81.A7.E5.AE.9A.E6.9C.9F.E7.9A.84.E3.81.AB_TRIM_.E3.82.92.E9.81.A9.E7.94.A8.E3.81.99.E3.82.8B)

### CLI 設定

筆者は、CLI 周りの環境は、
[yantene/config: dotfiles and great buddies](/yantene/config)
を `$HOME/.config` に `git clone` して整えています。

また、GUI 周りであったり、
プリンタに関するまとめであったりを
本リポジトリの `doc/` 下に配置しています。
いずれ整理するつもりで、
現在非常に雑然としていますが、参考にしてください。

### GUI 設定

lightdm & xmonad を使用する場合。
xmonad の設定はやはり
[yantene/config: dotfiles and great buddies](/yantene/config)
下にあるのでこれを `$HOME/.config` に `git clone` してください。
そして `/etc/lightdm/lightdm.conf` を編集し、以下の行を編集してください。

```conf
greeter-session=lightdm-mini-greeter
```

lightdm を有効化。

```shell-session
sudo systemctl enable --now lightdm.service
```

### 各種設定ファイルを配置

`files/` 下にはキースワップやタッチパッドの設定に関するファイルが置かれています。
環境に合わせて編集して配置してください。

### NTP 同期有効化

```shell-session
sudo timedatectl set-ntp true
```

### Snapper

`/` および `/home` を snapper の管理対象にします。

```shell-session
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
```

インストール直後の環境のスナップショットをとりあえず撮っておきます。

```shell-session
sudo snapper -c root create --description "init"
sudo snapper -c home create --description "init"
```

snapper でスナップショットを定期的に撮り、
またクリーンアップするようにします。

```shell-session
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
```

## その他

- `pacman.conf` に Color を追記

## 参考文献

インストールスクリプトの書き方には以下を参考にしました。

- [archlinux-autonistaller](/tukiyo/archlinux-autonistaller)
