#!/bin/bash
#===============================================================================
#      FILENAME: lbf_path.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-07-04 by leoxiang
#===============================================================================

function path::help {
  io::red "This is the help for LBF \"path\" lib: \n"
  io::red "See more help by call function with no args: \n"
  echo ""
  printf "%-40s %s\n" $(io::yellow "path::is_writable")   "return whether a file is writable"
  printf "%-40s %s\n" $(io::yellow "path::is_readable")   "return whether a file is readable"
  printf "%-40s %s\n" $(io::yellow "path::is_executable") "return whether a file is executable"
  printf "%-40s %s\n" $(io::yellow "path::is_exist")      "return whether a file/dir is exist"
  printf "%-40s %s\n" $(io::yellow "path::is_file")       "return whether a path is file"
  printf "%-40s %s\n" $(io::yellow "path::is_dir")        "return whether a path is directory"

  printf "%-40s %s\n" $(io::yellow "path::basename")      "get basename of a path"
  printf "%-40s %s\n" $(io::yellow "path::abs_pathname")  "get absolute-path from a relative-path"
  printf "%-40s %s\n" $(io::yellow "path::dirname")       "get parent directory of a path"
  printf "%-40s %s\n" $(io::yellow "path::suffix")        "get the suffix of path"
  printf "%-40s %s\n" $(io::yellow "path::cur_dirname")   "get the current directory path of this script"
}

############################################################
# path-related functions
############################################################
function path::basename {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  echo $(basename "$1")
}

function path::dirname {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  echo $(dirname "$1")
}

function path::absname {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  echo $(readlink -f "$1")
}

function path::suffix {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  echo ${1##*.}
}

function path::abs_pathname {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  readlink -f $1
}

function path::cur_dirname {
  path::dirname $0
}

############################################################
# bool functions
############################################################
function path::is_writable { 
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  [ -w "$1" ] && return 0 || return 1 
}

function path::is_readable { 
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  [ -r "$1" ] && return 0 || return 1 
}

function path::is_executable { 
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  [ -x "$1" ] && return 0 || return 1 
}

function path::is_exist { 
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  [ -e "$1" ] && return 0 || return 1 
}

function path::is_file { 
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  [ -f "$1" ] && return 0 || return 1 
}

function path::is_dir { 
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [path]" && return 1
  [ -d "$1" ] && return 0 || return 1 
}

############################################################
# Init and Check, Do Not Modify
############################################################
util::check_bin basename
util::check_bin dirname
util::check_bin readlink
util::check_bin test
util::check_bin echo
util::check_bin pwd

# vim:ts=2:sw=2:et:ft=sh:
