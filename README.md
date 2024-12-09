# README

## ToC

<!-- mtoc-start -->

* [Description](#description)
* [Requirements](#requirements)
* [Setup](#setup)
  * [Setup: apt](#setup-apt)
  * [Setup: ssh-keygen for github](#setup-ssh-keygen-for-github)
    * [ssh key generate](#ssh-key-generate)
    * [create ssh config for github](#create-ssh-config-for-github)
  * [Setup: argc](#setup-argc)
  * [Setup: pastel](#setup-pastel)
  * [Setup: sysctl](#setup-sysctl)
  * [Setup: ulimit](#setup-ulimit)
  * [Setup: Postfix](#setup-postfix)
    * [SendGrid API Key](#sendgrid-api-key)
    * [postfix main.cf](#postfix-maincf)
    * [reload postfix](#reload-postfix)
  * [Setup: easyrsa](#setup-easyrsa)
    * [Install easyrsa](#install-easyrsa)
    * [easyrsa init-pki](#easyrsa-init-pki)
    * [easyrsa build-ca](#easyrsa-build-ca)
    * [easyrsa build-server-full](#easyrsa-build-server-full)
    * [easyrsa gen-dh](#easyrsa-gen-dh)
* [Usage](#usage)
  * [init](#init)

<!-- mtoc-end -->

## Description

## Requirements

- [argc](https://github.com/sigoden/argc)
- [mustache for bash](https://github.com/tests-always-included/mo)
- [pastel](https://github.com/sharkdp/pastel)
- curl
- jq
- postfix
- libsasl2-modules
- openvpn
- wireguard
- sqlite3
- easy-rsa
- expect
- net-tools
- ipcalc-ng

> [!IMPORTANT]
>
> - 2024/12/05 時点でのGoogle Compute EngineのUbuntu 2404 LTS Minimul Imageをベースにしています。
> - [GitHub sigoden/argc]が必須です。
> - [mustache](https://mustache.github.io/)のbash用である[mo](https://github.com/tests-always-included/mo)が必須です。
> - [pastel](https://github.com/sharkdp/pastel)が使われています。
> - openvpn/wireguardのclient configを配布するためにPostfixとSendGrid APIが必須です。

## Setup

> [!IMPORTANT]
> rootで実施してください。

### Setup: apt

```bash
apt update && apt upgrade
apt install curl jq postfix libsasl2-modules openvpn wireguard sqlite3 easy-rsa expect net-tools ipcalc-ng
```

### Setup: ssh-keygen for github

#### ssh key generate

```bash
type=ed25519
sshkey=grasys_girhub.id_${type}
if [ ! -f ${HOME}/.ssh/${sshkey} ]; then
  ssh-keygen -t ${type} -f ${HOME}/.ssh/${sshkey}
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

### Setup: argc

[GitHub sigoden/argc - Pre-bulld Binaries](https://github.com/sigoden/argc?tab=readme-ov-file#pre-built-binaries)

```bash
curl -fsSL https://raw.githubusercontent.com/sigoden/argc/main/install.sh | \
  sudo sh -s -- --to /usr/local/bin
```

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

### Setup: sysctl

```bash
cd /opt/grasys-vpn-management
if [ ! -L /etc/sysctl.d/99_grasys_vpn.conf ]; then
  ln -s etc/sysctl.d/99_grasys_vpn.conf /etc/sysctl.d/99_grasys_vpn.conf
fi
sysctl -p
```

### Setup: ulimit

```bash
cd /opt/grasys-vpn-management
if [ ! -L /etc/security/limits.d/99_unlimited.conf ]; then
  ln -s etc/security/limits.d/99_unlimited.conf /etc/security/limits.d/99_unlimited.conf
fi
ulimit -a
```

### Setup: Postfix

[Google Cloud Compute Engine - Sending Email - Using SendGrid with Postfix](https://cloud.google.com/compute/docs/tutorials/sending-mail/using-sendgrid?hl=ja)

```bash
sudo apt install postfix libsasl2-modules
```

#### SendGrid API Key

- SendGridのAPIKeyを取得し、以下の環境変数SENDGRID_APIKEYにsetして以下を発行して下さい。
- mustacheをinstallする必要があります。

```bash
argc init

if [ -f contrib/mo/mo ]; then
  source contrib/mo/mo
if 

declare -x SENDGRID_APIKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
if [ -d /etc/postfix -a ! -f /etc/postfix/sasl_passwd ]; then
  cat templates/postfix/sasl_passwd.tmpl | mo > /etc/postfix/sasl_passwd
fi

postmap /etc/postfix/sasl_passwd
```

#### postfix main.cf

```bash
if [ ! -f /etc/postfix/main.cf.bak ]; then
  cp -p /etc/postfix/main.cf /etc/postfix/main.cf.bak
  sed -e "s/^default_transport = error$/#default_transport = error/m" /etc/postfix/main.cf
  sed -e "s/^relay_transport = error$/#relay_transport = error/m" /etc/postfix/main.cf
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
/etc/init.d/postfix reload
```

### Setup: easyrsa

#### Install easyrsa

```bash
apt install easy-rsa expect
```

#### easyrsa init-pki

```bash
cd /opt/grasys-vpn-management
/usr/share/easy-rsa/easyrsa init-pki
```

#### easyrsa build-ca

```bash
cd /opt/grasys-vpn-management

expect -c "
set timeout -1
spawn /usr/share/easy-rsa/easyrsa build-ca nopass
expect \"Easy-RSA CA\"
send \"grasys\n\"
interact
"

openssl x509 -in pki/ca.crt -text -noout | grep grasys
cat pki/ca.crt
```

#### easyrsa build-server-full

```bash
cd /opt/grasys-vpn-management

expect -c "
spawn /usr/share/easy-rsa/easyrsa build-server-full server nopass
expect \"Confirm request details\"
send \"yes\n\"
interact
"

openssl rsa -in pki/private/server.key -text -noout
cat pki/private/server.key
```

#### easyrsa gen-dh

```bash
/usr/share/easy-rsa/easyrsa gen-dh

openssl dhparam -in pki/dh.pem -text -noout
cat pki/dh.pem
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


