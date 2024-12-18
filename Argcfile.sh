#!/usr/bin/env bash
# @describe grasys openvpn/wireguard management tool
# @meta author i10 <ito@grasys.io>, yusukeh <hasegawa@grasys.io>
# @meta version 0.0.1
# @meta require-tools argc,pastel,jq,yq,curl,sqlite3,ipcalc-ng

###############################################################################
### for environments
# @meta dotenv .env.local
# @env mustache_deploy=contrib/mo
# @env mustache_repo=git@github.com:tests-always-included/mo.git
# @env config_openvpn=config/openvpn.yaml
# @env config_wireguard=config/wireguard.yaml
# @env users=config/users.yaml
# @env database=data/clients.sqlite3

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
    _info "Install mustache"
    _info "git clone ${mustache_repo}"
    git clone ${mustache_repo} ${mustache_deploy}
  elif [ -f ${mustache_deploy}/mo ]; then
    _info "pull mustache"
    _info "git -C ${mustache_deploy}/mo pull"
    git -C ${mustache_deploy} pull
  fi
}

function _load_mustache() {
  if [ -f ${mustache_deploy}/mo ]; then
    _info "load mustache ${mustache_deploy}/mo"
    source ${mustache_deploy}/mo
  fi
}

# for cleanup
function _clean() {
  if [ -d data ]; then
    _info "rm -rf data"
    rm -rf data
  fi
  if [ -d contrib ]; then
    _info "rm -rf contrib"
    rm -rf contrib
  fi
}

# for initialize directory
function _init_dirs() {
  if [ ! -d data ]; then
    _info "mkdir data"
    mkdir -p data
  fi
  if [ ! -d data/users ]; then
    _info "mkdir data/users"
    mkdir -p data/users
  fi
  if [ ! -d data/server_config_parts ]; then
    _info "mkdir data/server_config_parts"
    mkdir -p data/server_config_parts
  fi
  if [ ! -d contrib ]; then
    _info "mkdir contrib"
    mkdir -p contrib
  fi
}

# for sqlite3
function _create_sqlite() {
  if [ ! -f ${database} ]; then
    _info "create sqlite3 database ${database}"
    for f in $(ls -1 sql/create_table_*)
    do
      _info "sql file ${f}"
      sqlite3 ${database} < ${f}
    done
  fi
}

function _ip_to_num() {
  IFS=. read -r i1 i2 i3 i4 <<<"$1"
  echo $((i1 * 256**3 + i2 * 256**2 + i3 * 256 + i4))
}

function _num_to_ip() {
  echo "$((($1 >> 24) & 255)).$((($1 >> 16) & 255)).$((($1 >> 8) & 255)).$(($1 & 255))"
}

function _insert_wireguard_ipv4() {
  _info "wireguard ipv4"
  network=$(yq -r .ipv4.network < ${config_wireguard})
  _info "network ${network}"
  netmask=$(yq -r .ipv4.netmask < ${config_wireguard})
  _info "netmask ${netmask}"
  ip_min=$(ipcalc-ng --minaddr $network $netmask | sed -e "s/^MINADDR=//g")
  _info "ip_min ${ip_min}"
  ip_max=$(ipcalc-ng --maxaddr $network $netmask | sed -e "s/^MAXADDR=//g")
  _info "ip_max ${ip_max}"

  start_ip=$(_ip_to_num ${ip_min})
  _info "start_ip ${start_ip}"
  end_ip=$(_ip_to_num ${ip_max})
  _info "end_ip ${end_ip}"

  for ((i = ${start_ip}; i <= ${end_ip}; i++));
  do
    ipaddr=$(_num_to_ip $i)
    sql=$(cat templates/sqlite3/insert_wireguard_ipv4.sql | mo)
    sqlite3 ${database} "${sql}"
  done
}

function _ipcalc_ipv6() {
  python3 - <<EOF
import ipaddress
net = ipaddress.IPv6Network("${network}/${netmask}", strict=False)
for ip in net.hosts():
    print(ip)
EOF
}

function _insert_wireguard_ipv6() {
  _info "wireguard ipv6"
  network=$(yq -r .ipv6.network < ${config_wireguard})
  _info "network ${network}"
  netmask=$(yq -r .ipv6.netmask < ${config_wireguard})
  _info "netmask ${netmask}"
  ip_min=$(ipcalc-ng --minaddr $network/$netmask | sed -e "s/^MINADDR=//g")
  _info "ip_min ${ip_min}"
  ip_max=$(ipcalc-ng --maxaddr $network/$netmask | sed -e "s/^MAXADDR=//g")
  _info "ip_max ${ip_max}"

  for ipaddr in $(_ipcalc_ipv6 $network $netmask)
  do
    sql=$(cat templates/sqlite3/insert_wireguard_ipv6.sql | mo)
    sqlite3 ${database}	"${sql}"
  done
}

function _insert_client() {
  _info "insert client"

  email=$1
  private_key=$(wg genkey)
  public_key=$(echo $private_key | wg pubkey)

  sql=$(mo templates/sqlite3/insert_client.sql)
  sqlite3 ${database} "${sql}"
}

function _delete_client() {
  _info "delete client"

  email=$1

  sql=$(mo templates/sqlite3/delete_client.sql)
  sqlite3 ${database} "${sql}"
}

# for config
function _generate_wireguard_server_interface_part_config() {
  _info "generate wireguard server interface part config"

  email="root"

  _insert_client $email
  sql=$(mo templates/sqlite3/select_ipaddr4.sql)
  server_ipv4=$(sqlite3 ${database} "${sql}")
  sql=$(mo templates/sqlite3/select_ipaddr6.sql)
  server_ipv6=$(sqlite3 ${database} "${sql}")
  server_port=$(yq -r .port < ${config_wireguard})
  sql=$(mo templates/sqlite3/select_private_key.sql)
  server_private_key=$(sqlite3 ${database} "${sql}")

  cat templates/wireguard/server.conf | mo > data/server_config_parts/server_interface_part.conf
}

function _generate_wireguard_client_config() {
  _info "generate wireguard client config"

  if [ "$1" = "" ]
  then
    return
  fi

  email=$1

  _insert_client $email
  sql=$(mo templates/sqlite3/select_ipaddr4.sql)
  client_ipv4=$(sqlite3 ${database} "${sql}")
  sql=$(mo templates/sqlite3/select_ipaddr6.sql)
  client_ipv6=$(sqlite3 ${database} "${sql}")
  sql=$(mo templates/sqlite3/select_private_key.sql)
  client_private_key=$(sqlite3 ${database} "${sql}")
  sql=$(mo templates/sqlite3/select_public_key.sql)
  client_public_key=$(sqlite3 ${database} "${sql}")
  sql=$(mo templates/sqlite3/select_client_id.sql)
  client_0id=$(printf "%03d" $(sqlite3 ${database} "${sql}"))

  email="root"
  sql=$(mo templates/sqlite3/select_public_key.sql)
  server_public_key=$(sqlite3 ${database} "${sql}")
  sql=$(mo templates/sqlite3/select_ipaddr4.sql)
  server_ipv4=$(sqlite3 ${database} "${sql}")
  sql=$(mo templates/sqlite3/select_ipaddr6.sql)
  server_ipv6=$(sqlite3 ${database} "${sql}")
  server_port=$(yq -r .port < ${config_wireguard})

  endpoint_ipv4=$(curl -4 ipconfig.io)
  endpoint_ipv6=$(curl -6 ipconfig.io)

  endpoint=${endpoint_ipv4}
  cat templates/wireguard/client.conf | mo > data/users/client${client_0id}_ipv4.conf
  client_config_path_ipv4="data/users/client${client_0id}_ipv4.conf"

  endpoint="[${endpoint_ipv6}]"
  cat templates/wireguard/client.conf | mo > data/users/client${client_0id}_ipv6.conf
  client_config_path_ipv6="data/users/client${client_0id}_ipv6.conf"
}

function _generate_wireguard_server_peer_part_config() {
  _info "generate wireguard server peer part config"

  if [ "${client_0id}" = "" ]
  then
    return
  fi

#  client_public_key=$(sqlite3 ${database} "${sql}")
#  client_ipv4=$(sqlite3 ${database} "${sql}")
#  client_ipv6=$(sqlite3 ${database} "${sql}")

  cat templates/wireguard/server_peer_part.conf | mo > data/server_config_parts/server_peer_part${client_0id}.conf
}

function _concatenate_wireguard_server_config() {
  _info "concatenate wireguard server config"

  cat data/server_config_parts/{server_interface_part.conf,server_peer_part*.conf} > /etc/wireguard/wg0.conf
}

function _reload_wireguard_server_config() {
  _info "reload wireguard server config"

  systemctl stop wg-quick@wg0
  _concatenate_wireguard_server_config
  systemctl start wg-quick@wg0
}

###############################################################################
### argc sub-commands
# @cmd debug
debug() {
  _load_mustache
}

# @cmd cleanup
clean() {
  systemctl stop wg-quick@wg0
  _clean
}

# @cmd install mustache
install_mustache() {
  _install_mustache
}

# @cmd initialize
init() {
  _init_dirs
  _install_mustache
  _load_mustache
  _create_sqlite
  _insert_wireguard_ipv4
  _insert_wireguard_ipv6
  _generate_wireguard_server_interface_part_config
  _reload_wireguard_server_config
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
# @option -u --user!
# @flag -n --nomail
create_user() {
  _info "Create User"

  _load_mustache
  _generate_wireguard_client_config ${argc_user} # Return: client_config_path
  _generate_wireguard_server_peer_part_config
  _concatenate_wireguard_server_config
  _reload_wireguard_server_config

  if [ "${argc_nomail}" = "1" ]
  then
    echo 'nomail'
  else
    MAIL_BOUNDARY=`date +%Y%m%d%H%M%N`
    mail_from="grasys WireGuard Service <noreply@grasys.io>"
    mail_to="${argc_user}"
    mail_cc=""
    mail_bcc=""
    mail_subject="WireGuard VPN Client Config"
    mail_boundary=`date +%Y%m%d%H%M%N`
    mail_attachment1_filename="gratunl_ipv4.conf"
    mail_attachment1=`cat ${client_config_path_ipv4}`
    mail_attachment2_filename="gratunl_ipv6.conf"
    mail_attachment2=`cat ${client_config_path_ipv6}`
    cat templates/postfix/sendmail_to_user.tmpl | mo | sendmail -t
  fi
}

# @cmd create user
# @option -u --user!
delete_user() {
  _info "Delete User"

  _load_mustache
  email=${argc_user}
  sql=$(mo templates/sqlite3/select_client_id.sql)
  client_0id=$(printf "%03d" $(sqlite3 ${database} "${sql}"))
  rm data/server_config_parts/server_peer_part${client_0id}.conf
  rm data/users/client${client_0id}_ipv4.conf
  rm data/users/client${client_0id}_ipv6.conf
  _concatenate_wireguard_server_config
  _reload_wireguard_server_config
  _delete_client ${argc_user}
}

# @cmd show_users
show_users() {
  _info "Show Users"

  sqlite3 ${database} < sql/select_show_users.sql

}

###############################################################################
# See more details at https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"
