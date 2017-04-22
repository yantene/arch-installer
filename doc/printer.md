# 印刷設定

## CUPS のセットアップ
CUPS をインストール．
```bash
yaourt -S cups
```

サービスの有効化および起動．
```bash
sudo systemctl enable org.cups.cupsd.service
sudo systemctl start org.cups.cupsd.service
```

## 各プリンタの設定
### Canon PIXUS MG4230
ドライバのインストール．
```bash
yaourt -S cnijfilter-mg4200
```

プリンタのMACアドレスの検索．
```bash
sudo cnijnetprn --installer --search auto
```

見つかったプリンタを登録．
(スキームの後ろのスラッシュの数に注意)
```bash
sudo lpadmin -p MG4230 -m canonmg4200.ppd -v cnijnet:/**-**-**-**-**-** -E
```

デフォルトのプリンタとして登録(したければ)．
```bash
sudo lpadmin -d MG4230
```

### Brother DCP7065DN
ドライバのインストール
```bash
yaourt -S brother-dcp7065dn
```

IPアドレスを調べ，プリンタを登録．
```bash
sudo lpadmin -p DCP7065DN -m brother-BrGenML1-cups-en.ppd -v socket://192.168.1.9 -E
```
