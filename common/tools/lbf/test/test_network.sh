#!/bin/bash
#===============================================================================
#      FILENAME: test_network.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-07-05 by leoxiang
#===============================================================================

PATH="$(dirname $0)/../lbf:$PATH"
source lbf_init.sh

var_ssh_host="127.0.0.1"
var_ssh_user="xiangkun"
var_ssh_passwd="ximi"
var_ssh_port="22"

var_ip_conf="$(path::cur_dirname)/ip.conf"

test::run

test::test_case test_bool_func {
  test::assert network::is_valid_ip "127.0.0.1"
  test::assert network::is_valid_ip "255.255.255.254"
  test::assert ! network::is_valid_ip "1000.0..1"
  test::assert ! network::is_valid_ip "200"
  test::assert ! network::is_valid_ip "192.168.1.1.1"

  test::assert network::is_valid_port "8888"
  test::assert network::is_valid_port "2"
  test::assert ! network::is_valid_port "65537"

  test::assert network::is_lan_ip "192.168.1.1"
  test::assert network::is_lan_ip "172.168.1.1"
  test::assert network::is_lan_ip "10.0.0.1"
  test::assert ! network::is_lan_ip "221.0.0.1"
  test::assert ! network::is_lan_ip "135.0.0.1"
  
  test::assert ! network::is_wan_ip "192.168.1.1"
  test::assert ! network::is_wan_ip "172.168.1.1"
  test::assert ! network::is_wan_ip "10.0.0.1"
  test::assert network::is_wan_ip "221.0.0.1"
  test::assert network::is_wan_ip "135.0.0.1"

  test::assert ! network::is_wan_ip "10.0..1"
  test::assert ! network::is_lan_ip "10.0.1.1.1"
}

test::test_case test_ip_func {
  echo $(io::yellow "all ip:") "$(network::all_ip)"
  echo $(io::yellow "wan ip:") "$(network::lan_ip)"
  echo $(io::yellow "lan ip:") "$(network::wan_ip)"
  echo $(io::yellow "login ip:") "$(network::login_ip)"
  echo $(io::yellow "eth0 ip:") "$(network::ip_for_iface eth0)"

  test::assert_equal 2130706433 network::inet_aton "127.0.0.1"
  test::assert_equal 3232235777 network::inet_aton "192.168.1.1"

  test::assert_equal "127.0.0.1"   network::inet_ntoa 2130706433
  test::assert_equal "192.168.1.1" network::inet_ntoa 3232235777
}

test::test_case test_ssh_func {
  echo $(io::yellow "ssh script location:") "$LBF_SCRIPT_SSH"

  #test::assert_equal $var_ssh_user network::ssh_do $var_ssh_passwd $var_ssh_port $var_ssh_user@$var_ssh_host whoami
}

#test::test_case test_batch_ssh_do {
  #network::batch_ssh_do $var_ip_conf 'echo show example of network::batch_ssh_do'
#}

# vim:ts=2:sw=2:et:ft=sh:
