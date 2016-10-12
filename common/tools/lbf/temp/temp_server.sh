#!/bin/bash
#===============================================================================
#      FILENAME: temp_server.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-02-08 by leoxiang
#===============================================================================

PATH="$(dirname $0)/lbf:$PATH"
source lbf_init.sh

############################################################
# User-defined variable
############################################################
# server settings
export var_project_path=$(path::abs_pathname $(path::dirname $0)/..)
export var_log_file="${var_project_path}/log/server.log"
export var_backup_dir="${var_project_path}/backup"
export var_backup_files=(bin conf script)
export var_alarm_target=(leoxiang)
# hash config
export var_app_hash_num="8"
export var_cache_hash_num="16"
export var_hash_shm_key="0x00008800"
export var_rank_shm_key="0x00009800"
# command
var_cmd_inter="./bin/logic_inter conf/logic_inter.conf"
var_cmd_app="./bin/logic_app conf/logic_app.conf"
var_cmd_cache="./bin/logic_cache conf/logic_cache.conf"
var_cmd_rank="./bin/logic_rank conf/logic_rank.conf"
var_cmd_sync="./bin/logic_sync conf/logic_sync.conf"

############################################################
# Main Logic
############################################################
function usage {
  echo "Usage: $(path::basename $0) [start|stop|restart] [all|inter|app|cache|sync|rank]"
  echo "       $(path::basename $0) [status|checklive]   [all|inter|app|cache|sync|rank]"
  echo "       $(path::basename $0) [backup|rollback]"
  echo "       $(path::basename $0) [clearshm]"
}

function main {
  cd ${var_project_path}
  ulimit -s 81920

  case $1 in 
    start)      shift; do_start         ${@};;
    stop)       shift; do_stop          ${@};;
    restart)    shift; do_restart       ${@};;
    backup)     shift; server::backup   ${@};;
    rollback)   shift; server::rollback ${@};;
    status)     shift; do_status        ${@};;
    checklive)  shift; do_checklive     ${@};;
    clearshm)   shift; do_clearshm      ${@};;
    *)          usage;;
  esac
  io::no_output cd -
}

function do_start {
  case $1 in
      all) do_start inter
           do_start app
           do_start cache
           do_start rank
           do_start sync;;
    inter) server::start ${var_cmd_inter};;
      app) for ((hash = 0; hash < ${var_app_hash_num}; hash++)); do
             server::start ${var_cmd_app} ${hash}
           done ;;
    cache) for ((hash = 0; hash < ${var_cache_hash_num}; hash++)); do
             server::start ${var_cmd_cache} ${hash}
           done ;;
     rank) server::start ${var_cmd_rank};;
     sync) server::start ${var_cmd_sync};;
        *) usage;;
  esac
}

function do_stop {
  case $1 in
      all) do_stop inter
           do_stop app
           do_stop cache
           do_stop rank
           do_stop sync;;
    inter) server::stop ${var_cmd_inter};;
      app) for ((hash = 0; hash < ${var_app_hash_num}; hash++)); do
             server::stop ${var_cmd_app} ${hash}
           done ;;
    cache) for ((hash = 0; hash < ${var_cache_hash_num}; hash++)); do
             server::stop ${var_cmd_cache} ${hash}
           done ;;
     rank) server::stop ${var_cmd_rank};;
     sync) server::stop ${var_cmd_sync};;
        *) usage;;
  esac
}

function do_restart {
  case $1 in
      all) do_restart inter
           do_restart app
           do_restart cache
           do_restart rank
           do_restart sync;;
    inter) server::restart ${var_cmd_inter};;
      app) for ((hash = 0; hash < ${var_app_hash_num}; hash++)); do
             server::restart ${var_cmd_app} ${hash}
           done ;;
    cache) for ((hash = 0; hash < ${var_cache_hash_num}; hash++)); do
             server::restart ${var_cmd_cache} ${hash}
           done ;;
     rank) server::restart ${var_cmd_rank};;
     sync) server::restart ${var_cmd_sync};;
        *) usage;;
  esac
}

function do_status {
  case $1 in
      all) do_status inter
           do_status app
           do_status cache
           do_status rank
           do_status sync;;
    inter) server::status ${var_cmd_inter};;
      app) server::status ${var_cmd_app};;
    cache) server::status ${var_cmd_cache} ;;
     rank) server::status ${var_cmd_rank};;
     sync) server::status ${var_cmd_sync};;
        *) usage;;
  esac
}

function do_checklive {
  case $1 in
      all) do_checklive inter
           do_checklive app
           do_checklive cache
           do_checklive rank
           do_checklive sync;;
    inter) server::checklive 1  ${var_cmd_inter}  || do_restart "$1";;
      app) server::checklive 8  ${var_cmd_app}    || do_restart "$1";;
    cache) server::checklive 16 ${var_cmd_cache}  || do_restart "$1";;
     rank) server::checklive 1  ${var_cmd_rank}   || do_restart "$1";;
     sync) server::checklive 1  ${var_cmd_sync}   || do_restart "$1";;
        *) usage;;
  esac
}

function do_clearshm {
  read -p "clear shm will lose all user data, please confirm [yes/no]: " var_confirm
  [ ${var_confirm} != "yes" ] && return

  for ((_idx = 0; _idx < ${var_cache_hash_num}; _idx++)); do
    ipcrm -M $((${var_hash_shm_key} + ${_idx}))
  done

  ipcrm -M ${var_rank_shm_key}

  do_restart cache
  do_restart rank
}

############################################################
# MOST OF TIMES YOU DO NOT NEED TO CHANGE THESE
############################################################
#################################
# process-related funcs
function server::status {
  util::is_empty $1 && echo "Usage: ${FUNCNAME} [process_name]" && return 1

  echo "$(path::basename $1) running process num is: " $(server::get_running_num $1)
}

function server::is_alive {
  util::is_empty $1 && echo "Usage: ${FUNCNAME} [process_name]" && return 1

  io::no_output pgrep -xf "${*}" && return 0 || return 1
}

function server::get_running_num {
  util::is_empty $1 && echo "Usage: ${FUNCNAME} [process_name]" && return 1

  local _num=$(pgrep -x $(path::basename $1) | wc -l)
  util::is_empty ${_num} && echo 0 && return 1
  echo ${_num}
}

function server::start {
  util::is_empty $1 && echo "Usage: ${FUNCNAME} [process_cmd]" && return 1

  ! server::is_alive "${@}" && eval "${@}"
  ulimit -c unlimited

  # if no process, sleep 100msec then see again
  if server::is_alive "${@}"; then
    io::log_info ${var_log_file} "succeed start $@"
  else
    usleep 100000
    server::is_alive "${@}" && io::log_info ${var_log_file} "succeed start $@" || io::log_warn ${var_log_file} "failed start $@"
  fi
}

function server::stop {
  util::is_empty $1 && echo "Usage: ${FUNCNAME} [process_cmd]" && return 1

  server::is_alive "${@}" && pkill -xf "${*}"
  # make sure the process is killed
  server::is_alive "${@}" && usleep 100000 && server::is_alive "${@}" && pkill -9 -xf "${*}"
  io::log_info ${var_log_file} "succeed stop $@"
}

function server::restart {
  util::is_empty $1 && echo "Usage: ${FUNCNAME} [process_cmd]" && return 1

  # kill process
  server::is_alive "${@}" && pkill -xf "${*}"
  server::is_alive "${@}" && usleep 100000 && server::is_alive "${@}" && pkill -9 -xf "${*}"

  # restart process
  eval "${@}"
  ulimit -c unlimited
  if server::is_alive "${@}"; then
    io::log_info ${var_log_file} "succeed restart $@"
  else
    usleep 100000
    server::is_alive "${@}" && io::log_info ${var_log_file} "succeed restart $@" || io::log_warn ${var_log_file} "failed restart $@"
  fi
}

function server::checklive {
  util::is_empty $2 && echo "Usage: ${FUNCNAME} [process_num] [process_cmd]" && return 1

  local _process_num="$1" && shift
  local _process_cur_num="$(server::get_running_num ${@})"
  if [ ${_process_cur_num} -lt ${_process_num} ]; then
    server::alarm "$(path::basename $1) running num is ${_process_cur_num}, restart it"
    return 1
  fi
  return 0
}

function server::alarm {
  util::is_empty $1 && echo "Usage: ${FUNCNAME} [message]" && return 1

  for target in ${var_alarm_target[@]}; do
    util::alarm msg ${target} "$(hostname): ${@}"
  done
  io::log_error ${var_log_file} "${@}"
}

#################################
# backup-related funcs
function server::backup {
  # generate backup dir using current time
  local _base_dir="${var_backup_dir}/$(date +"%Y-%m-%d_%H-%M-%S")"

  # backup each file once a time
  for _src in ${var_backup_files[@]}; do
    echo "starting to backup \"${_src}\""
    local _dest_dir="$(path::dirname ${_base_dir}/${_src})"
    ! path::is_exist ${_dest_dir} && mkdir -p ${_dest_dir}
    cp -rf ${_src} ${_dest_dir}
  done

  # write log
  io::log_info ${var_log_file} "succeed backup files to ${_dest_dir}"
}

function server::rollback {
  # output instruct msg
  echo "select which version you want to rollback"

  # restore files
  select _dir in $(ls ${var_backup_dir}); do
    local _dest_dir="${var_backup_dir}/${_dir}"
    echo "you select ${_dest_dir}, these file will be restored: " && find ${_dest_dir} -type f
    cp -rf ${_dest_dir}/* ${var_project_path}
    break
  done

  # write log
  io::log_info ${var_log_file} "succeed restore files from ${_dest_dir}"
}

#################################
# here we start the main logic
main "${@}"

# vim:ts=2:sw=2:et:ft=sh:
