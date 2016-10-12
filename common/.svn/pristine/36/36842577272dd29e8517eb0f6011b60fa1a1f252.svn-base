#!/bin/bash
#===============================================================================
#      FILENAME: temp_mysql.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-08-28 by leoxiang
#===============================================================================

PATH="$(dirname $0)/lbf:$PATH"
source lbf_init.sh

############################################################
# User-defined variable
############################################################
# mysql setting
var_mysql_bin="tmysqls"
var_db_user="root"
var_db_passwd="tpy@sec"
var_db_host="localhost"
var_db_port="3306"
var_db_socket="/data1/mysql_3307/mysqld.sock"
var_db_name="tpymtkn"

# master slave setting
var_master_ip="10.153.137.38"
var_slave_ip="172.25.38.64"
var_hash_cnt=200

############################################################
# Main Logic
############################################################
function usage {
  echo "Usage: $(path::basename $0) [install]" 
  echo "       $(path::basename $0) [create|clear]"
  echo "       $(path::basename $0) [setmaster|setslave]"
  echo "       $(path::basename $0) [checkslave]"
  echo "       $(path::basename $0) [coldbackup]"
}

#TODO do_install do_setmaster do_setslave 
function main {
  cd $var_project_path

  # main entry
  case $1 in 
    install)    shift; do_install     ${@};;
    create)     shift; do_create    ${@};;
    clear)      shift; do_clear     ${@};;
    setmaster)  shift; do_setmaster   ${@};;
    setslave)   shift; do_setslave    ${@};;
    checkslave) shift; do_checkslave  ${@};;
    coldbackup) shift; do_coldbackup  ${@};;
    *)          usage;;
  esac

  io::no_output cd -
}

function do_install {
  mysql -uroot -p <<SQL
    use mysql;
    delete from user where user='';
    delete from user where user='root' and Host!='localhost';
    flush privileges;
SQL
}

##################################################
# Create Talbes
function do_create {
  # create database if need
  mysql::execute "CREATE DATABASE IF NOT EXISTS $var_db_name CHARACTER SET utf8 COLLATE utf8_general_ci;"

  # create tables
  for (( idx = 0; idx < $var_hash_cnt; idx++ )); do
    echo "start to create tbl_user for $idx"
    mysql::execute $var_db_name <<SQL
    CREATE TABLE IF NOT EXISTS tbl_user_$idx (
      fapp_id      INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '业务类型',
      fuser_id     BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
      ftkn_id      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '令牌序列号',
      fuin_id      INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '业务ID对应的QQ号',
      fbind_ip     INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的客户IP',
      fbind_time   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的时间',
      fbind_status INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定关系的状态',
      fnickname    CHAR(64) 			 NOT NULL DEFAULT 0 COMMENT '用户的昵称',
      freserved1   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段1',
      freserved2   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段2',
      freserved3   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段3',
      freserved4   CHAR(64) 			 NOT NULL DEFAULT 0 COMMENT '保留字段4',
      PRIMARY KEY (fapp_id, fuser_id)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SQL
  done

  for (( idx = 0; idx < $var_hash_cnt; idx++ )); do
    echo "start to create tbl_tkn2user for $idx"
    mysql::execute $var_db_name <<SQL
    CREATE TABLE IF NOT EXISTS tbl_tkn2user_$idx (
      fapp_id      INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '业务类型',
      ftkn_id      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '令牌序列号',
      fuser_id0    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
      fuser_id1    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
      fuser_id2    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
      fuser_id3    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
      fuser_id4    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
      fmodify_ip   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改token的客户IP',
      fmodify_time INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改token属性的时间',
      freserved1   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段1',
      freserved2   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段2',
      freserved3   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段3',
      freserved4   CHAR(64) 			 NOT NULL DEFAULT 0 COMMENT '保留字段4',
      PRIMARY KEY (fapp_id, ftkn_id)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SQL
  done

  for (( idx = 0; idx < $var_hash_cnt; idx++ )); do
    echo "start to create tbl_uin2tkn for $idx"
    mysql::execute $var_db_name <<SQL
    CREATE TABLE IF NOT EXISTS tbl_uin2tkn_$idx (
      fuin_id      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '业务ID对应的QQ号',
      ftkn_id      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '令牌序列号',
      fmodify_ip   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改uin和token对应关系的客户IP',
      fmodify_time INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改uin和token对应关系的时间',
      fapp_bitmap  BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留了UIN和UID映射关系的APP位图',
      freserved1   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段1',
      freserved2   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段2',
      freserved3   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段3',
      freserved4   CHAR(64) 			 NOT NULL DEFAULT 0 COMMENT '保留字段4',
      PRIMARY KEY (fuin_id)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SQL
  done

  for (( idx = 0; idx < $var_hash_cnt; idx++ )); do
    echo "start to create tbl_user_his for $idx"
    mysql::execute $var_db_name <<SQL
    CREATE TABLE IF NOT EXISTS tbl_user_his_$idx (
      fapp_id         BIGINT     UNSIGNED NOT NULL DEFAULT 0  COMMENT '业务类型',
      fuser_id        BIGINT     UNSIGNED NOT NULL DEFAULT 0  COMMENT '绑定token的用户的id',
      ftkn_id         BIGINT     UNSIGNED NOT NULL DEFAULT 0  COMMENT '令牌序列号',
      fuin_id         BIGINT     UNSIGNED NOT NULL DEFAULT 0  COMMENT '业务ID对应的QQ号',
      fbind_ip        INT        UNSIGNED NOT NULL DEFAULT 0  COMMENT '绑定token的客户IP',
      fbind_time      INT        UNSIGNED NOT NULL DEFAULT 0  COMMENT '绑定token的时间',
      funbind_ip      INT        UNSIGNED NOT NULL DEFAULT 0  COMMENT '解绑token的客户IP',
      funbind_time    INT        UNSIGNED NOT NULL DEFAULT 0  COMMENT '解绑token的时间',
      INDEX (fapp_id, fuser_id)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
SQL
  done

  # create merge tables
  local var_tbl_user_list=""
  local var_tbl_tkn2user_list=""
  local var_tbl_uin2tkn_list=""
  local var_tbl_user_his_list=""

  for (( idx = 0; idx < $var_hash_cnt; idx++)); do
    var_tbl_user_list+="tbl_user_$idx"
    var_tbl_tkn2user_list+="tbl_tkn2user_$idx"
    var_tbl_uin2tkn_list+="tbl_uin2tkn_$idx"
    var_tbl_user_his_list+="tbl_user_his_$idx"
    if [ $idx -ne $(( $var_hash_cnt - 1 )) ]; then
      var_tbl_user_list+=","
      var_tbl_tkn2user_list+=","
      var_tbl_uin2tkn_list+=","
      var_tbl_user_his_list+=","
    fi
  done

  mysql::execute $var_db_name <<SQL
  CREATE TABLE IF NOT EXISTS tbl_user_mrg (
    fapp_id      INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '业务类型',
    fuser_id     BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
    ftkn_id      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '令牌序列号',
    fuin_id      INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '业务ID对应的QQ号',
    fbind_ip     INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的客户IP',
    fbind_time   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的时间',
    fbind_status INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定关系的状态',
    fnickname    CHAR(64) 			 NOT NULL DEFAULT 0 COMMENT '用户的昵称',
    freserved1   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段1',
    freserved2   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段2',
    freserved3   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段3',
    freserved4   CHAR(64) 			 NOT NULL DEFAULT 0 COMMENT '保留字段4',
    PRIMARY KEY (fapp_id, fuser_id)
  ) ENGINE=MRG_MyISAM INSERT_METHOD=LAST CHARSET=utf8 UNION=($var_tbl_user_list);

  CREATE TABLE IF NOT EXISTS tbl_tkn2user_mrg (
    fapp_id      INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '业务类型',
    ftkn_id      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '令牌序列号',
    fuser_id0    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
    fuser_id1    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
    fuser_id2    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
    fuser_id3    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
    fuser_id4    BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定token的用户的id',
    fmodify_ip   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改token的客户IP',
    fmodify_time INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改token属性的时间',
    freserved1   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段1',
    freserved2   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段2',
    freserved3   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段3',
    freserved4   CHAR(64) 			 NOT NULL DEFAULT 0 COMMENT '保留字段4',
    PRIMARY KEY (fapp_id, ftkn_id)
  ) ENGINE=MRG_MyISAM INSERT_METHOD=LAST CHARSET=utf8 UNION=($var_tbl_tkn2user_list);

  CREATE TABLE IF NOT EXISTS tbl_uin2tkn_mrg (
    fuin_id      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '业务ID对应的QQ号',
    ftkn_id      BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '令牌序列号',
    fmodify_ip   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改uin和token对应关系的客户IP',
    fmodify_time INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '最后修改uin和token对应关系的时间',
    fapp_bitmap  BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留了UIN和UID映射关系的APP位图',
    freserved1   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段1',
    freserved2   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段2',
    freserved3   INT    UNSIGNED NOT NULL DEFAULT 0 COMMENT '保留字段3',
    freserved4   CHAR(64) 			 NOT NULL DEFAULT 0 COMMENT '保留字段4',
    PRIMARY KEY (fuin_id)
  ) ENGINE=MRG_MyISAM INSERT_METHOD=LAST CHARSET=utf8 UNION=($var_tbl_uin2tkn_list);

  CREATE TABLE IF NOT EXISTS tbl_user_his_mrg (
    fapp_id         BIGINT     UNSIGNED NOT NULL DEFAULT 0  COMMENT '业务类型',
    fuser_id        BIGINT     UNSIGNED NOT NULL DEFAULT 0  COMMENT '绑定token的用户的id',
    ftkn_id         BIGINT     UNSIGNED NOT NULL DEFAULT 0  COMMENT '令牌序列号',
    fuin_id         BIGINT     UNSIGNED NOT NULL DEFAULT 0  COMMENT '业务ID对应的QQ号',
    fbind_ip        INT        UNSIGNED NOT NULL DEFAULT 0  COMMENT '绑定token的客户IP',
    fbind_time      INT        UNSIGNED NOT NULL DEFAULT 0  COMMENT '绑定token的时间',
    funbind_ip      INT        UNSIGNED NOT NULL DEFAULT 0  COMMENT '解绑token的客户IP',
    funbind_time    INT        UNSIGNED NOT NULL DEFAULT 0  COMMENT '解绑token的时间',
    INDEX (fapp_id, fuser_id)
  ) ENGINE=MRG_MyISAM INSERT_METHOD=LAST CHARSET=utf8 UNION=($var_tbl_user_his_list);
SQL
}

function do_clear {
  for (( idx = 0; idx <= $var_hash_cnt; idx++ )); do
    echo "start to clear tbl_user, tbl_tkn2user, tbl_uin2tkn, tbl_user_his for $idx"

    do_mysql $var_db_name "
      DELETE FROM tbl_user_$idx;
      DELETE FROM tbl_tkn2user_$idx;
      DELETE FROM tbl_uin2tkn_$idx;
      DELETE FROM tbl_user_his_$idx;"
  done
}

function do_setmaster {

}

function do_setslave {

}

function do_checkslave {

}

function do_coldbackup {

}

############################################################
# MOST OF TIMES YOU DO NOT NEED TO CHANGE THESE
############################################################
function mysql::execute {
  local args=""
  ! util::is_empty $var_db_user   && args+=" -u$var_db_user"
  ! util::is_empty $var_db_passwd && args+=" -p$var_db_passwd"
  ! util::is_empty $var_db_host   && args+=" -h$var_db_host"
  ! util::is_empty $var_db_port   && args+=" -P$var_db_port"
  ! util::is_empty $var_db_socket && args+=" -S$var_db_socket"

  $var_mysql_bin $args $@
}


#################################
# here we start the main logic
main "${@}"

# vim:ts=2:sw=2:et:ft=sh:
