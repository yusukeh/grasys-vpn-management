#!/usr/bin/env bash
# @describe grasys openvpn/wireguard management tool
# @meta author i10 <ito@grasys.io>, yusukeh <hasegawa@grasys.io>
# @meta version 0.0.1
# @meta require-tools jq,curl
# @meta dotenv .env.local

set -e



# See more details at https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"
