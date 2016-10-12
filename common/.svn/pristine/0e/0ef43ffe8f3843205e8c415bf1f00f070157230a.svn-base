#!/bin/bash
#===============================================================================
#      FILENAME: lbf_array.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-06-26 by leoxiang
#===============================================================================

function array::help {
  io::red "This is the help for LBF \"array\" lib: \n"
  io::red "See more help by call function with no args: \n"
  echo ""
  printf "%-40s %s\n" $(io::yellow "array::init")       "initiate an array"
  printf "%-40s %s\n" $(io::yellow "array::size")       "return the size of an array"
  printf "%-40s %s\n" $(io::yellow "array::get")        "get array item by index"
  printf "%-40s %s\n" $(io::yellow "array::all")        "get all items of an array, can specify delimiter"
  printf "%-40s %s\n" $(io::yellow "array::add")        "add an item to an array"
  printf "%-40s %s\n" $(io::yellow "array::del")        "delete an item from an array"
  printf "%-40s %s\n" $(io::yellow "array::del_by_idx") "delete an item from an array by index"
  printf "%-40s %s\n" $(io::yellow "array::free")       "free an array"
}

############################################################
# array functions
############################################################
function array::init {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [array]" && return 1
  eval "$1=()"
}

function array::init {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [array]" && return 1
  eval "$1=()"
}

function array::size {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [array]" && return 1
  eval echo "\${#$1[@]}"
}

function array::get {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [array] [index]" && return 1
  (($2 < 0 || $2 >= $(array::size $1))) && return 1
  eval "echo \${$1[$2]}"
}

function array::all {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [array] [delimit(opt)]" && return 1
  for _idx in $(eval echo "\${!$1[@]}"); do
    eval echo -ne "\${$1[${_idx}]}"
    echo -ne "${2:-\n}"
  done
}

function array::add {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [array] [item...]" && return 1
  local _array="$1" && shift
  while [ $# -gt 0 ]; do
    eval "${_array}=(\"\${${_array}[@]}\" \"$1\")"
    shift
  done
}

function array::del {
  util::is_empty "$2" && echo "Usage: ${FUNCNAME} [array] [item...]" && return 1
  local _array="$1" && shift

  for _item in "$@"; do
    for _idx in $(eval echo "\${!${_array}[@]}"); do
      eval echo "\${${_array}[${_idx}]}" | grep "^${_item}$" &>/dev/null && eval unset "${_array}[$_idx]"
    done
  done
  eval "${_array}=(\"\${${_array}[@]}\")"
}

function array::del_by_idx {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [array] [index]" && return 1
  local _array="$1" && shift
  eval "unset ${_array}[$1]"
  eval "${_array}=(\"\${${_array}[@]}\")"
}

function array::free {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [array]" && return 1
  eval unset "$1"
}

# vim:ts=2:sw=2:et:ft=sh:
