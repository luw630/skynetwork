#!/bin/bash
#===============================================================================
#      FILENAME: lbf_network.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-07-04 by leoxiang
#===============================================================================

function network::help {
  io::red "This is the help for LBF \"network\" lib: \n"
  io::red "See more help by call function with no args: \n"
  echo ""
  printf "%-40s %s\n" $(io::yellow "network::is_valid_ip")        "return whether it is a valid ip"
  printf "%-40s %s\n" $(io::yellow "network::is_valid_port")      "return whether it is a valid port"
  printf "%-40s %s\n" $(io::yellow "network::is_lan_ip")          "return whether it is a \"local area network\" ip"
  printf "%-40s %s\n" $(io::yellow "network::is_wan_ip")          "return whether it is a \"wide area network\" ip"
  printf "%-40s %s\n" $(io::yellow "network::all_ip")             "get all ip from ifconfig, not include 127.0.0.1"
  printf "%-40s %s\n" $(io::yellow "network::lan_ip")             "get \"local area network\" ip from ifconfig"
  printf "%-40s %s\n" $(io::yellow "network::wan_ip")             "get \"wide area network\" ip from ifconfig"
  printf "%-40s %s\n" $(io::yellow "network::login_ip")           "get login host ip when using ssh"
  printf "%-40s %s\n" $(io::yellow "network::inet_ntoa")          "convert ip num to doted ip address"
  printf "%-40s %s\n" $(io::yellow "network::inet_aton")          "convert doted ip address to ip num"
  printf "%-40s %s\n" $(io::yellow "network::convert_byte_order") "convert byte order for integer"
  printf "%-40s %s\n" $(io::yellow "network::ssh_do")             "execute bash command in a remote host"
  printf "%-40s %s\n" $(io::yellow "network::ssh_copy")           "copy files to a remote host"
  printf "%-40s %s\n" $(io::yellow "network::batch_ssh_do")     "execute bash command in several server define in server list"
}

############################################################
# bool function
############################################################
function network::is_valid_ip {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [ip] " && return 1

  #TODO: this is not perfect
  [ "$1" == "0.0.0.0" ] && return 1
  [ "$1" == "255.255.255.255" ] && return 1
  ! (echo $1 | grep -Eq '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$') && return 1
  return 0
}

function network::is_valid_port {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [port] " && return 1
  (($1 >= 1)) && (($1 <= 65535)) && return 0 
  return 1
}

function network::is_lan_ip {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [ip] " && return 1

  ! network::is_valid_ip "$1" && return 1
  ! (echo $1 | grep -Eq '^(192|172|10).*$' ) && return 1
  return 0
}

function network::is_wan_ip {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [ip] " && return 1

  ! network::is_valid_ip "$1" && return 1
  (echo $1 | grep -Eq '^(192|172|10).*$' ) && return 1
  return 0
}

############################################################
# ip functions
############################################################
function network::all_ip {
  ifconfig | \
    grep "inet addr" | \
    grep -v "127.0.0.1" | \
    sed -re "s/.*inet addr:([^ ]*).*/\1/"
}

function network::lan_ip {
  for _ip in $(network::all_ip); do
    network::is_lan_ip ${_ip} && echo ${_ip}
  done
}

function network::wan_ip {
  for _ip in $(network::all_ip); do
    network::is_wan_ip ${_ip} && echo ${_ip}
  done
}

function network::login_ip {
  for _ip in $(echo $SSH2_CLIENT    | awk '{ print $1 }' ) \
             $(echo $SSH_CONNECTION | awk '{ print $1 }' ) \
             $(echo $SSH_CLIENT     | awk '{ print $1 }' ) ; do
    echo ${_ip}
  done
}

function network::ip_for_iface {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [if_name(ep:eth0)] " && return 1

  io::no_output ! ifconfig $1 && return 1
  ifconfig $1 | \
    grep "inet addr" | \
    sed -re "s/.*inet addr:([^ ]*).*/\1/"
}

function network::inet_ntoa {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [ip_addr]" && return 1
  for ((_idx = 3; _idx >= 0; _idx--)); do
    printf $(($1 >> ( $_idx * 8 ) & 0xff))
    [ $_idx -ne 0 ] && printf "." || printf "\n"
  done
}

function network::inet_aton {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [dotted_ip_addr]" && return 1
  util::to_dec "0x$(printf "%02x" ${1//./ })"
}

function network::convert_byte_order {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [byte-num] [uint]" && return 1
  local _tmp=0
  for ((_idx = 0; _idx < $1 / 2; _idx++)); do
    let _tmp+=$(( ($2 & (0xff << $_idx * 8))            << ($1 - $_idx - 1) * 8 ))
    let _tmp+=$(( ($2 & (0xff << ($1 - $_idx - 1) * 8)) >> ($1 - $_idx - 1) * 8 ))
  done
  echo $_tmp
}

############################################################
# SSH-related functions
############################################################
function network::ssh_do {
  util::is_empty "$4" && echo "Usage: ${FUNCNAME} [passwd] [port] [user]@[host] [bash_cmd]" && return 1
  local _var_passwd="$1" && shift
  local _var_port="$1" && shift
  ${LBF_SCRIPT_SSH} ${_var_passwd} ssh -p ${_var_port} "$@" | \
    sed -re "s/[^[:print:]]+//g" | \
    sed -re "/^.*'s password:.*$/d" | \
    sed -re "/^Authentication successful.*$/d" | \
    sed -re "/^$/d" \
    && ( exit ${PIPESTATUS[0]} )
}

function network::ssh_copy {
  util::is_empty "$4" && echo "Usage: ${FUNCNAME} [passwd] [port] [user1]@[host1]:[file1] [user2]@[host2]:[file2]" && return 1
  local _var_passwd="$1" && shift
  local _var_port="$1" && shift
  ${LBF_SCRIPT_SSH} ${_var_passwd} scp -P ${_var_port} -r "$@" | \
    sed -re "s/[^[:print:]]+//g" | \
    sed -re "/^.*'s password:/d" | \
    sed -re "/^Authentication successful/d" | \
    sed -re "/^$/d" | \
    sed -re "/^Received signal 1\. \(no core\)/d"
}

function network::batch_ssh_do {
  if util::is_empty "$2"; then
    echo "Usage: ${FUNCNAME} [server_list_file] [bash_cmd]"
    echo ""
    echo "  File Format: PASSWD PORT USER HOST"
    echo "  Notice: func will ignore empty line and commented line (start with #)"
    return 1
  fi
  local _file="$1" && shift
  cat ${_file} | sed -re "/^#.*$/d" | sed -re "/^[:space:]*$/d" | \
    while read _line; do
    local _args=(${_line})
    io::yellow "[START] ${_args[2]} ${_args[3]} ${_args[1]}\n"
    network::ssh_do ${_args[0]} ${_args[1]} ${_args[2]}@${_args[3]} "$@"
    io::yellow "[ END ] ${_args[2]} ${_args[3]} ${_args[1]}\n"
  done
}

############################################################
# Initiation, Do Not Modify
############################################################
util::check_bin ssh
util::check_bin ifconfig
util::check_bin expr
util::check_bin grep

# find basic ssh expect script
util::is_empty ${LBF_SCRIPT_SSH} && LBF_SCRIPT_SSH="$(util::find_script basic_ssh.exp)"
util::is_empty ${LBF_SCRIPT_SSH} && echo "Cant find LBF_SCRIPT_SSH" && return 1
export LBF_SCRIPT_SSH

# vim:ts=2:sw=2:et:ft=sh:
