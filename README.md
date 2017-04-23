# Arch installer

EFI 環境および GPT BIOS 環境に Arch Linux をインストールするスクリプトです．
筆者が Arch Linux の環境構築する際に使用しているスクリプトを公開しているものです．

EFI 環境向けのスクリプト `setup.efi.sh` は
QEMU 環境および SONY VAIO Pro (SVP1321A1J)，
BIOS 環境向けのスクリプト `setup.gpt_bios.sh` は
QEMU 環境および SONY VAIO T (SVT1311AJ) で検証しました．

なお，本スクリプトの使用は自己責任でお願いいたします．

## 本スクリプトの特徴

- EFI 環境，BIOS 環境ともに GPT でパーティショニングします．
  - EFI 環境のブートローダは systemd-boot です．
  - BIOS 環境のブートローダは GRUB です．
- ファイルシステムは BTRFS を利用します．
  - インストール直後の環境は自動でスナップショットを撮ります．
- ミラーサーバは日本近辺のサーバをベタ書きしています．
- エディタとして neovim を標準でインストールします．

## 使い方

まず，Arch のインストールメディアをインストールしたい対象環境でブートします．
この時点で，対象環境が EFI マシンか BIOS のマシンかを把握しておきます．
確認方法は以下を参照してください．

[インストールガイド - ArchWiki 起動モードの確認](https://wiki.archlinuxjp.org/index.php/%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB%E3%82%AC%E3%82%A4%E3%83%89#.E8.B5.B7.E5.8B.95.E3.83.A2.E3.83.BC.E3.83.89.E3.81.AE.E7.A2.BA.E8.AA.8D)

次に，インターネット接続を行います．
環境に合わせて `wifi-menu` なり `dhcpcd` なりを叩きましょう．

最後に，本リポジトリのシェルスクリプトをダウンロードします．
インストールメディアに `git` が入っていないので，
`curl` を使うのが一番手軽な方法かと思います．

```bash
curl -L goo.gl/bE0EMj > setup.sh # EFI 環境の場合
curl -L goo.gl/wGlFfp > setup.sh # BIOS 環境の場合
```

後は`setup.sh`をおもむろに実行し，
指示に従って以下の項目を入力します．
- インストール先デバイス (デフォルト値: /dev/sda)
- ホスト名 (デフォルト値: YanteneLaptop)
- ユーザ名 (デフォルト値: yantene)
- パスワード (root と上記ユーザ名のユーザは同じパスワードとなります)
- スワップ領域のサイズ (デフォルト値: 0)

## 参考文献

インストールスクリプトの書き方には以下を参考にしました．

- [archlinux-autonistaller](https://github.com/tukiyo/archlinux-autonistaller)
