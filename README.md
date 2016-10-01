# Arch installer

EFI 環境および GPT BIOS 環境に Arch Linux をインストールするスクリプトです．
自分が環境構築する際に使用しているスクリプトを公開しているものです．

EFI 環境向けのスクリプト `setup.efi.sh` は
QEMU 環境および SONY VAIO Pro (SVP1321A1J)，
GPT BIOS 環境向けのスクリプト `setup.gpt_bios.sh` は
QEMU 環境および SONY VAIO T (SVT1311AJ) で検証しました．

なお，本スクリプトの使用は自己責任でお願いいたします．

## 使い方

まず USB ブートにて Arch 環境を立ち上げます．
次に， `wifi-menu` などでインターネット接続を行います．
最後に，本リポジトリにある `setup.{efi,gpt_bios}.sh` を実行し，
ホスト名，作成するユーザ名，および作成するパスワードを入力し，
しばらく待つことでインストールは完了します．

## 参考文献

インストールスクリプトの書き方には以下を参考にしました．

- [archlinux-autonistaller](https://github.com/tukiyo/archlinux-autonistaller)
