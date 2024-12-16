# README

## ToC

<!-- mtoc-start -->

* [Description](#description)
* [Requirements](#requirements)
* [Setup](#setup)
  * [Setup: apt](#setup-apt)
  * [Setup: ssh-keygen for github](#setup-ssh-keygen-for-github)
    * [create .gitconfig](#create-gitconfig)
    * [ssh key generate](#ssh-key-generate)
    * [create ssh config for github](#create-ssh-config-for-github)
    * [git authentication test](#git-authentication-test)
    * [git clone](#git-clone)
  * [Setup: argc](#setup-argc)
  * [Setup: pastel](#setup-pastel)
  * [Setup: sysctl](#setup-sysctl)
  * [Setup: pam](#setup-pam)
  * [Setup: ulimit](#setup-ulimit)
  * [Setup: Postfix](#setup-postfix)
    * [SendGrid API Key](#sendgrid-api-key)
    * [postfix main.cf](#postfix-maincf)
    * [reload postfix](#reload-postfix)
    * [test e-mail](#test-e-mail)
  * [systemctl wg-quick@wg0](#systemctl-wg-quickwg0)
* [Usage](#usage)
  * [init](#init)

<!-- mtoc-end -->

## Description

grasys Incのwireguardを管理するツールです。

基本的にはCommand-Lineのみのツールになっています。

ToDo: 運用管理用のREADME-ops.md を作成し、ここにリンク予定

## Requirements

- [argc](https://github.com/sigoden/argc)
- [mustache for bash](https://github.com/tests-always-included/mo)
- [pastel](https://github.com/sharkdp/pastel)
- curl
- git
- iptables
- jq
- postfix
- libsasl2-modules
- wireguard
- sqlite3
- net-tools
- ipcalc-ng

> [!IMPORTANT]
>
> - 2024/12/05 時点でのGoogle Compute EngineのUbuntu 24.04 LTS Minimal Imageをベースにしています。
> - [argc](https://github.com/sigoden/argc) が必須です。
> - [mustache](https://mustache.github.io/) のbash用である [mo](https://github.com/tests-always-included/mo) が必須です。
> - [pastel](https://github.com/sharkdp/pastel) が使われています。（長谷川の趣味です・・・）
> - wireguardのclient configを配布するためにPostfixとSendGrid APIが必須です。

## Setup

> [!IMPORTANT]
> rootで実施してください。

### Setup: apt

```bash
apt update && apt upgrade
apt install curl git iptables jq yq wireguard sqlite3 net-tools ipcalc-ng neovim
```

```bash
reboot
```

### Setup: ssh-keygen for github

#### create .gitconfig

```bash
git_user="XXXXXXXXXX"
git_email="xxxxxx@grasys.io"
git config --global user.name "${git_user}"
git config --global user.email "${git_email}"

cat ${HOME}/.gitconfig
```

#### ssh key generate
> [!TIP]
> 鍵生成(次のコマンド実行)時に暗号化保存のためのパスプレーズ(passphrase)が質問されますが、何も入力せずEnter のみ入力することで暗号化されない(使用時にパスフレーズ不要)鍵が生成されます。

```bash
type=ed25519
sshkey=grasys_girhub.id_${type}
comment="$(git config user.name) <$(git config user.email)> created at $(date +%Y%m%d)"
if [ ! -f ${HOME}/.ssh/${sshkey} ]; then
  ssh-keygen -t ${type} -C "${comment}" -f ${HOME}/.ssh/${sshkey}
fi
```

#### create ssh config for github

```bash
if [ ! -f ${HOME}/.ssh/config ]; then
cat << EOL > ${HOME}/.ssh/config
Host github.com
  IdentityFile ~/.ssh/${sshkey}
  User git
  IdentitiesOnly yes

TCPKeepAlive yes
StrictHostKeyChecking no
ServerAliveInterval 10
ServerAliveCountMax 3
EOL
fi
```

#### git authentication test

> [!IMPORTANT]
> 20241216時点でのrepositoryは[yusukeh/grasys-vpn-management](https://github.com/yusukeh/grasys-vpn-management)となっているため、gitの権限追加はyusukehに伝えてください。

```bash
git -T git@github.com
```

> [!TIP]
> もしErrorが出るなら

```bash
git -vvvv -T git@github.com
```

#### git clone

```bash
if [ ! -d /opt/grasys-vpn-management ]; then
  git clone git@github.com:yusukeh/grasys-vpn-management.git /opt/grasys-vpn-management
fi
cd /opt/grasys-vpn-management
```

### Setup: argc

[GitHub sigoden/argc - Pre-bulld Binaries](https://github.com/sigoden/argc?tab=readme-ov-file#pre-built-binaries)

```bash
curl -fsSL https://raw.githubusercontent.com/sigoden/argc/main/install.sh | \
  sudo sh -s -- --to /usr/local/bin
```

> [!TIP]
> 確認コマンドは以下

```bash
which argc
argc --argc-help
```

### Setup: pastel

[GitHub sharkdp/pastel - On Debian-based systems](https://github.com/sharkdp/pastel?tab=readme-ov-file#on-debian-based-systems)

```bash
cd /opt/grasys-vpn-management
url="https://github.com/sharkdp/pastel/releases/download/v0.8.1/pastel_0.8.1_amd64.deb"
deb=$(basename ${url})
test ! -d tmp && mkdir tmp
curl -fsSL -o tmp/${deb} ${url}
sudo dpkg -i tmp/${deb}
```

> [!TIP]
> 確認コマンドは以下

```bash
which pastel
```

### Setup: sysctl

> [!IMPORTANT]
> /opt/grasys-vpn-management/etc/sysctl.d/99_grasys_vpn.confの中身を良く確認しましょう。

```bash
cd /opt/grasys-vpn-management
if [ ! -L /etc/sysctl.d/99_grasys_vpn.conf ]; then
  ln -s /opt/grasys-vpn-management/etc/sysctl.d/99_grasys_vpn.conf /etc/sysctl.d/99_grasys_vpn.conf
fi
sysctl --system
```

> [!TIP]
> 確認コマンドは以下

```bash
for s in $(cat etc/sysctl.d/99_grasys_vpn.conf | grep -v "^$" | awk -F'=' '{print $1}');
do
  sysctl $s
done
```

### Setup: pam

> [!IMPORTANT]
> けっこう危険なので気を付けてｗ

```bash
declare pam_files=(/etc/pam.d/common-session /etc/pam.d/common-session-noninteractive)
for f in ${pam_files[@]}
do
  grep "session required ppam_limits.so" ${f} &> /dev/null
  res=$?
  if [ $res -ne 0 ]; then
    echo "session required pam_limits.so" >> ${f}
    cat ${f}
  fi
done
```

### Setup: ulimit

```bash
cd /opt/grasys-vpn-management
if [ ! -L /etc/security/limits.d/99_unlimited.conf ]; then
  ln -s /opt/grasys-vpn-management/etc/security/limits.d/99_unlimited.conf /etc/security/limits.d/99_unlimited.conf
fi
ulimit -a
```

### Setup: Postfix

[Google Cloud Compute Engine - Sending Email - Using SendGrid with Postfix](https://cloud.google.com/compute/docs/tutorials/sending-mail/using-sendgrid?hl=ja)

> [!TIP]
> Postfix パッケージ(メール転送エージェント)をインストールする際、対話的に事前設定項目を質問されるので「5. Local only」など適宜回答して進みます。
> ToDo: 回答項目を手順に盛り込む

```bash
sudo apt install postfix libsasl2-modules
```

#### SendGrid API Key

- SendGridのAPIKeyを取得し、以下の環境変数SENDGRID_APIKEYにsetして以下を発行して下さい。
- mustacheをinstallする必要があります。

> [!IMPORTANT]
> SENDGRID API Keyは社内でも権限を持っている人が少ないため、CIのリーダー格以上、Managerラインに聞いてください。

```bash
argc install_mustache

if [ -f contrib/mo/mo ]; then
  source contrib/mo/mo
fi 

declare -x SENDGRID_APIKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
if [ -d /etc/postfix -a ! -f /etc/postfix/sasl_passwd ]; then
  cat templates/postfix/sasl_passwd.tmpl | mo > /etc/postfix/sasl_passwd
fi

postmap /etc/postfix/sasl_passwd
if [ ! -f /etc/postfix/sasl_passwd.db ]; then
  echo "/etc/postfix/sasl_passwd.db not exists."
fi
```

#### postfix main.cf

```bash
if [ ! -f /etc/postfix/main.cf.bak ]; then
  cp -p /etc/postfix/main.cf /etc/postfix/main.cf.bak
  sed -e "s/^default_transport = error$/#default_transport = error/m" /etc/postfix/main.cf > /etc/postfix/main.cf
  sed -e "s/^relay_transport = error$/#relay_transport = error/m" /etc/postfix/main.cf > /etc/postfix/main.cf
  cat <<EOL >> /etc/postfix/main.cf

# for SendGrid
relayhost = [smtp.sendgrid.net]:2525
smtp_tls_security_level = encrypt
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
header_size_limit = 4096000
smtp_sasl_security_options = noanonymous
EOL
fi
```

#### reload postfix

```bash
if [ -f /etc/postfix/sasl_passwd.db ]; then
  /etc/init.d/postfix reload
else
  echo "/etc/postfix/sasl_passwd.db not exist."
  echo "  just run"
  echo "  postmap /etc/postfix/sasl_passwd"
fi
```

#### test e-mail

```bash
cat <<EOL | /usr/lib/sendmail -t
To: ito@grasys.io
Cc: hasegawa@grasys.io
Subject: test e-mail from ${HOSTNAME}

${HOSTNAME}
test e-mail
EOL
```

### systemctl wg-quick@wg0

```bash
cd /opt/grasys-vpn-management
declare interface=$(yq -r .interface config/wireguard.yaml)
systemctl enable wg-quick@${interface}
systemctl status wg-quick@${interface}
```

> [!TIP]
> systemctl edit wg-quick@${interface}
> このコマンドでService SectionのLimitNOFILEを修正します。

```bash
cd /opt/grasys-vpn-management
declare interface=$(yq -r .interface config/wireguard.yaml)
vi /etc/systemd/system/multi-user.target.wants/wg-quick@wg0.service
```

```bash
[Service]
LimitNOFILE=65535
```

## Usage

### init

- directory生成
- install mustache
- load mustache
- create sqlite3 clients database
- insert wireguard ipv4 range ip addresses
- insert wireguard ipv6 range ip addresses

```bash
argc init
```

生成されたclients.sqlite3の確認

```bash
sqlite3 data/clients.sqlite3 "SELECT * FROM wireguard_ipv4"
sqlite3 data/clients.sqlite3 "SELECT * FROM wireguard_ipv6"

sqlite3 data/clients.sqlite3 "SELECT count(*) FROM wireguard_ipv4"
sqlite3 data/clients.sqlite3 "SELECT count(*) FROM wireguard_ipv6"
```
