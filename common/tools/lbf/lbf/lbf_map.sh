#!/bin/bash
#===============================================================================
#      FILENAME: lbf_map.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-07-03 by leoxiang
#===============================================================================

############################################################
# map functions
############################################################
function map::init {
  util::is_empty "$1" && echo "Usage: ${FUNCNAME} [map]" && return 1
  eval "$1=()"

}

function map::add {
  util::is_empty "$3" && echo "Usage: ${FUNCNAME} [map] [key] [value]" && return 1

}

# vim:ts=2:sw=2:et:ft=sh:
