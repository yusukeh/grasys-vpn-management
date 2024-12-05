# README

## ToC

<!-- mtoc-start -->

- [Description](#description)
- [Requirements](#requirements)
- [Setup](#setup)
  - [Setup: argc](#setup-argc)
  - [Setup: Postfix](#setup-postfix)
    - [SendGrid API Key](#sendgrid-api-key)
- [Usage](#usage)

<!-- mtoc-end -->

## Description

## Requirements

- [argc](https://github.com/sigoden/argc)
- [mustache for bash](https://github.com/tests-always-included/mo)
- postfix
- openvpn
- wireguard
- curl
- jq

> [!IMPORTANT]
>
> - 2024/12/05時点でのGoogle Compute EngineのUbuntu 2404 LTS Imageをベースにしています。
> - [GitHub sigoden/argc]が必須です。
> - [mustache](https://mustache.github.io/)のbash用である[mo](https://github.com/tests-always-included/mo)が必須です。
> - openvpn/wireguardのclient configを配布するためにPostfixとSendGrid APIが必須です。

## Setup

### Setup: argc

[GitHub sigoden/argc - Pre-bulld Binaries](https://github.com/sigoden/argc?tab=readme-ov-file#pre-built-binaries)

```bash
curl -fsSL https://raw.githubusercontent.com/sigoden/argc/main/install.sh | sudo sh -s -- --to /usr/local/bin
```

```bash
which argc
argc --argc-help
```

### Setup: Postfix

[Google Cloud Compute Engine - Sending Email - Using SendGrid with Postfix](https://cloud.google.com/compute/docs/tutorials/sending-mail/using-sendgrid?hl=ja)

```bash
sudo apt install postfix libsasl2-modules
```

#### SendGrid API Key

SendGridのAPIKeyを取得し、以下の環境変数SENDGRID_APIKEYにsetして以下を発行して下さい。

```bash
SENDGRID_APIKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
cat <<EOL > .env.local
SENDGRID_APIKEY=${SENDGRID_APIKEY}
EOL
```

## Usage
