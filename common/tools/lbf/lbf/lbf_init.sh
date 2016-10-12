#!/bin/bash
#===============================================================================
#      FILENAME: lbf_init.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-05-31 by leoxiang
#===============================================================================

############################################################
# Init Main
############################################################
function lbf_init {
  # set bash opt
  shopt -s expand_aliases
  shopt -s shift_verbose
  shopt -s sourcepath

  # source depend script
  ! source lbf_util.sh    && return 1
  ! source lbf_io.sh      && return 1
  ! source lbf_array.sh   && return 1
  ! source lbf_path.sh    && return 1
  ! source lbf_map.sh     && return 1
  ! source lbf_network.sh && return 1
  ! source lbf_test.sh    && return 1

  # declare lbf version
  io::no_output lbf_version
}

############################################################
# Helper Func
############################################################
function lbf_version {
  export LBF_VERSION="7"
  echo "LBF Current Version: ${LBF_VERSION}"
}

function lbf_help {
  io::red "This is the help for LBF ${LBF_VERSION}: \n"
  io::red "See more help by type command below: \n"
  io::red "\n"
  io::red "[LIB]\n"
  printf '%-30s %s\n' $(io::yellow "util::help")    "provide some useful ultility"
  printf '%-30s %s\n' $(io::yellow "path::help")    "provide path-related operations"
  printf '%-30s %s\n' $(io::yellow "network::help") "provide network-related operations, ssh execute, ssh sopy..."
  printf '%-30s %s\n' $(io::yellow "io::help")      "provide io-related operations, colorful io, log..."
  printf '%-30s %s\n' $(io::yellow "array::help")   "provide abstract data type: array"
  io::red "\n"
  io::red "[COMMAND]\n"
  printf '%-30s %s\n' "$(io::yellow "lbf_version")"     "show lbf version"
}

############################################################
# Entry, Do Not Modify
############################################################
lbf_init

# vim:ts=2:sw=2:et:ft=sh:
