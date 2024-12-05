#!/usr/bin/env bash
# @describe grasys openvpn/wireguard management tool
# @meta author i10 <ito@grasys.io>, yusukeh <hasegawa@grasys.io>
# @meta version 0.0.1
# @meta require-tools argc,pastel,jq,curl

###############################################################################
### for environments
# @meta dotenv .env.local
# @env mustache_deploy=contrib/mo
# @env mustache_repo=git@github.com:tests-always-included/mo.git

###############################################################################
### for bash mode
set -e

###############################################################################
### functions
function _debug() {
  pastel paint cyan --bold "  DEBUG: $@"
}

function _info() {
  pastel paint limegreen --bold "  INFO: $@"
}

function _error() {
  pastel paint red --bold "  ERROR: $@"
}

# for mustache
function _install_mustache() {
  if [ ! -d ${mustache_deploy} ]; then
    _info "git clone ${mustache_repo}"
    git clone ${mustache_repo} ${mustache_deploy}
  elif [ -f ${mustache_deploy}/mo ]; then
    _info "git pull ${mustache_deploy}/mo"
    cd ${mustache_deploy}
    git pull
  fi
}

function _load_mustache() {
  if [ -f ${mustache_deploy}/mo ]; then
    _info "load mustache ${mustache_deploy}/mo"
    source ${mustache_deploy}/mo
  fi
}

###############################################################################
### argc sub-commands
# @cmd install mustache
install_mustache() {
  _info "Install mustache"
  _install_mustache
}

# @cmd setup wireguard
setup_wireguard() {
  _info "Setup WireGuard"
}

# @cmd setup openvpn
setup_openvpn() {
  _info "Setup OpenVPN"
}

# @cmd create user
# @option --user!
create_user() {
  _info "Create User"

  _debug "${argc_user}"
}


###############################################################################
# See more details at https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"
