#!/bin/bash
#===============================================================================
#      FILENAME: lbf_io.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-07-04 by leoxiang
#===============================================================================

function io::help {
  io::red "This is the help for LBF \"io\" lib: \n"
  io::red "See more help by call function with no args: \n"
  echo ""
  printf "%-40s %s\n" $(io::yellow "io::redirect_output")   "do commands and redirect output to a file"
  printf "%-40s %s\n" $(io::yellow "io::copy_output")       "do commands and cpoy output to a file"
  printf "%-40s %s\n" $(io::yellow "io::no_output")         "do commands and do not output"
  printf "%-40s %s\n" $(io::red    "io::red")               "output contents with red color"
  printf "%-40s %s\n" $(io::green  "io::green")             "output contents with green color"
  printf "%-40s %s\n" $(io::yellow "io::yellow")            "output contents with yellow color"
  printf "%-40s %s\n" $(io::blue   "io::blue")              "output contents with blue color"
  printf "%-40s %s\n" $(io::purple "io::purple")            "output contents with purple color"
  printf "%-40s %s\n" $(io::white  "io::white")             "output contents with white color"

  printf "%-40s %s\n" $(io::yellow "io::log")               "write log to a specified file"
  printf "%-40s %s\n" $(io::yellow "io::log_info")          "write info log to a specified file"
  printf "%-40s %s\n" $(io::yellow "io::log_warn")          "write warn log to a specified file"
  printf "%-40s %s\n" $(io::yellow "io::log_error")         "write error log to a specified file"
}

############################################################
# IO-related functions
############################################################
function io::redirect_output {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [out_file] [cmd..]" && return 1

  local _var_out_file="$1" && shift
  "$@" >>"${_var_out_file}" 2>&1
}

function io::copy_output {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [out_file] [cmd..]" && return 1

  local _var_out_file="$1" && shift
  "$@" | tee -a "${_var_out_file}" && ( exit ${PIPESTATUS[0]} )
}

function io::no_output {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [cmd..]" && return 1
  io::redirect_output /dev/null "$@"
}

############################################################
# color functions
############################################################
function io::red {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [content..]" && return 1
  io::color red "$@"
}

function io::green {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [content..]" && return 1
  io::color green "$@"
}

function io::yellow {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [content..]" && return 1
  io::color yellow "$@"
}

function io::blue {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [content..]" && return 1
  io::color blue "$@"
}

function io::purple {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [content..]" && return 1
  io::color purple "$@"
}

function io::white {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [content..]" && return 1
  io::color white "$@"
}

function io::color {
  local _var_color_red="\e[1m\e[31m"
  local _var_color_green="\e[1m\e[32m"
  local _var_color_yellow="\e[1m\e[33m"
  local _var_color_blue="\e[1m\e[34m"
  local _var_color_purple="\e[1m\e[35m"
  local _var_color_white="\e[1m\e[37m"
  local _var_color_end="\e[m"

  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [red|green|yellow|blue|purple|white] [content..]" && return 1
  case "$1" in
    "red")    echo -ne ${_var_color_red}    ;;
    "green")  echo -ne ${_var_color_green}  ;;
    "yellow") echo -ne ${_var_color_yellow} ;;
    "blue")   echo -ne ${_var_color_blue}   ;;
    "purple") echo -ne ${_var_color_purple} ;;
    "white")  echo -ne ${_var_color_white}  ;;
    *)        echo "Unkown color: $1" && return 1 ;;
  esac

  shift && echo -ne "$@"${_var_color_end}
}

############################################################
# log functions
############################################################
function io::log {
  util::is_empty "$3" && echo "Usage: ${FUNCNAME} [log_level] [log_file] [string...]" && return 1

  local _var_log_level="$1" && shift
  local _var_log_file="$1" && shift
  mkdir -p $(path::dirname ${_var_log_file})
  io::copy_output ${_var_log_file} echo "|$(date +'%Y-%m-%d|%H:%M:%S')|${_var_log_level} $@"
}

function io::log_info {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [log_file] [string...]" && return 1
  io::log INF "$@"
}

function io::log_warn {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [log_file] [string...]" && return 1
  io::log WRN "$@"
}

function io::log_error {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [log_file] [string...]" && return 1
  io::log ERR "$@"
}

function io::daily_log {
  util::is_empty "$3" && echo "Usage: ${FUNCNAME} [log_level] [log_file] [string...]" && return 1

  local _var_log_level="$1" && shift
  local _var_log_file="$1.$(date +'%Y-%m-%d')" && shift
  io::copy_output ${_var_log_file} echo "|$(date +'%Y-%m-%d|%H:%M:%S')|${_var_log_level} $@"
}

function io::daily_log_info {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [log_file] [string...]" && return 1
  io::daily_log INF "$@"
}

function io::daily_log_warn {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [log_file] [string...]" && return 1
  io::daily_log WRN "$@"
}

function io::daily_log_error {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [log_file] [string...]" && return 1
  io::daily_log ERR "$@"
}

############################################################
# Init and Check, Do Not Modify
############################################################
util::check_bin tee
util::check_bin date
util::check_bin touch

# vim:ts=2:sw=2:et:ft=sh:
