# README

## ToC

<!-- mtoc-start -->

- [Description](#description)
- [Requirements](#requirements)
- [Setup](#setup)
  - [Setup: ssh-keygen for github](#setup-ssh-keygen-for-github)
    - [ssh key generate](#ssh-key-generate)
    - [create ssh config for github](#create-ssh-config-for-github)
  - [Setup: argc](#setup-argc)
  - [Setup: pastel](#setup-pastel)
  - [Setup: Postfix](#setup-postfix)
    - [SendGrid API Key](#sendgrid-api-key)
    - [postfix main.cf](#postfix-maincf)
  - [Setup: easyrsa](#setup-easyrsa)
- [Usage](#usage)
- [Appendix](#appendix)
  - [easyrsa](#easyrsa)
    - [Install easyrsa](#install-easyrsa)
    - [init](#init)
    - [build ca](#build-ca)

<!-- mtoc-end -->

## Description

## Requirements

- [argc](https://github.com/sigoden/argc)
- [mustache for bash](https://github.com/tests-always-included/mo)
- [pastel](https://github.com/sharkdp/pastel)
- postfix
- openvpn
- wireguard
- curl
- jq

> [!IMPORTANT]
>
> - 2024/12/05 時点でのGoogle Compute EngineのUbuntu 2404 LTS Minimul Imageをベースにしています。
> - [GitHub sigoden/argc]が必須です。
> - [mustache](https://mustache.github.io/)のbash用である[mo](https://github.com/tests-always-included/mo)が必須です。
> - [pastel](https://github.com/sharkdp/pastel)が使われています。
> - openvpn/wireguardのclient configを配布するためにPostfixとSendGrid APIが必須です。

## Setup

### Setup: ssh-keygen for github

#### ssh key generate

```bash
type=ed25519
sshkey=grasys_girhub.id_${type}
ssh-keygen -t ed25519 -f ${HOME}/.ssh/${sshkey}
```

#### create ssh config for github

```bash
cat << EOL > .ssh/config
Host github.com
  IdentityFile ~/.ssh/${sshkey}
  User git
  IdentitiesOnly yes

TCPKeepAlive yes
StrictHostKeyChecking no
ServerAliveInterval 10
ServerAliveCountMax 3
EOL
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
url="https://github.com/sharkdp/pastel/releases/download/v0.8.1/pastel_0.8.1_amd64.deb"
deb=$(basename ${url})
curl -fsSL -o tmp/${deb} ${url}
sudo dpkg -i tmp/${deb}
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
argc install_mustache

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

### Setup: easyrsa

```bash
suto apt install easy-rsa
```

## Usage

---

# Appendix

## easyrsa

### Install easyrsa

```bash
sudo apt install easyrsa
```

### init

```bash
cd /opt/grasys-vpn-management
/usr/share/easy-rsa/easyrsa init-pki
```

### build ca

```bash
cd /opt/grasys-vpn-management
/usr/share/easy-rsa/easyrsa build-ca
```
