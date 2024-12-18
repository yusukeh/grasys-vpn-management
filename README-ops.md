# 運用管理用マニュアル

* セットアップ手順(README.md)が完了していること

# ToC

<!-- mtoc-start -->

* [運用作業環境への遷移](#運用作業環境への遷移)
  * [VPNサーバへのログイン](#vpnサーバへのログイン)
  * [管理者ユーザ(root)昇格](#管理者ユーザroot昇格)
  * [作業ディレクトリへの移動](#作業ディレクトリへの移動)
  * [ユーザ確認(一覧)](#ユーザ確認一覧)
  * [ユーザ作成](#ユーザ作成)

<!-- mtoc-end -->

# 運用作業環境への遷移
## VPNサーバへのログイン
オフィスネットワーク/Mac 等ローカル環境からログインを想定
```sh
gcloud compute ssh dualstack-vpn-server --zone 'asia-northeast1-b' --project 'trial-pritunl'
```

## 管理者ユーザ(root)昇格
```sh
sudo su -
```
以降root での作業前提
## 作業ディレクトリへの移動
```sh
cd /opt/grasys-vpn-management/
```

# 
## ユーザ確認(一覧)
```sh
argc show_users
```

出力例
```sh
root@ds-test-vpn-server:/opt/grasys-vpn-management# argc show_users
  INFO: Show Users
id|email|ipaddr|ipaddr
1|root|192.168.242.1|fd00::c0a8:f201
2|ito@grasys.io|192.168.242.2|fd00::c0a8:f202
root@ds-test-vpn-server:/opt/grasys-vpn-management#
```

## ユーザ作成
```sh
user_email="ito+test@grasys.io"

argc create_user
  --user ${user_email}
```

作成時にメールを送らない場合
```sh
argc create_user
  --user ${user_email}
  --nomail
```

## ユーザ削除
```sh
user_email="ito+test@grasys.io"

argc delete_user
  --user ${user_email}
```
