# Arch installer

UEFI 環境に Arch Linux をインストールするスクリプトです。
QEMU 環境および SONY VAIO Pro (SVP132A1CN) で検証しました。

## 使い方

まず USB ブートにて Arch 環境を立ち上げます。
次に、 `wifi-menu` などでインターネット接続を行います。
最後に、本リポジトリにある `installer.sh` を実行し、
ホスト名、作成するユーザ名、
および root と作成したユーザのパスワード (同一) を入力し、
しばらく待つことでインストールは完了します。

## 構築環境

- Boot loader
  - systemd-boot
- File system
  - FAT (as EFI system partition)
  - Btrfs (as Root partition)
    - subvolume `root` (`/` without `/home`)
    - subvolume `home` (`/home`)
- Users
  - root
    - zsh
  - new user
    - zsh
    - wheel
- Package manager
  - mirror servers
    - Japan
    - Taiwan
    - China
    - etc.
  - yaourt

重要そうなことは以上にまとめました。
詳しくは[ブログ記事]()をご覧ください。

## 参考文献

インストールスクリプトの書き方には以下を参考にしました。

- [archlinux-autonistaller](https://github.com/tukiyo/archlinux-autonistaller)
