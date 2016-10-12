#!/bin/bash
#===============================================================================
#      FILENAME: lbf_test.sh
#
#   DESCRIPTION: ---
#         NOTES: TODO fix test_case order problem
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-07-03 by leoxiang
#===============================================================================

############################################################
# unit test functions
############################################################
function test::test_case {
  exit 0
}

function test::run {
  # re-parse the file
  local _expr="$(cat "$0" | \
    sed -re "s/^test::test_case ([-_:[:alnum:]]+)/function test::test_case_\1/" | \
    sed -re "s/(test::assert[-_:[:alnum:]]*)/\1 \$LINENO/" | \
    sed -re "/test::run/d")"
  eval "${_expr}"

  # run all the test case 
  local _idx=1
  for _case in $(declare | sed -re "/^test::test_case_/!d" -e "s/^([-_:[:alnum:]]+) .*$/\1/"); do
    printf "\e[1m\e[32m""[ Test %03d ] %s""\e[m""\n" "${_idx}" "${_case}"
    _idx=$((_idx + 1))
    eval ${_case}
    printf "\n"
  done
  exit 0
}

############################################################
# assert functions
############################################################
function test::assert_function {
  local _line_num=$(($1 - 23)) && shift

  if [ $1 == "!" ]; then
    shift
    if command -v "$1" &>/dev/null; then 
      echo -ne "\e[1m\e[31m""[  Failed  ] ""\e[m"
    else
      echo -ne "\e[1m\e[32m""[  Passed  ] ""\e[m"
    fi
  elif command -v "$1" &>/dev/null; then
    echo -ne "\e[1m\e[32m""[  Passed  ] ""\e[m"
  else
    echo -ne "\e[1m\e[31m""[  Failed  ] ""\e[m"
  fi
  echo "$(basename "$0")|${_line_num}|assert_function $@"
}

function test::assert {
  local _line_num=$(($1 - 23)) && shift

  if [ $1 == "!" ]; then
    shift
    if "$@"; then 
      echo -ne "\e[1m\e[31m""[  Failed  ] ""\e[m"
    else
      echo -ne "\e[1m\e[32m""[  Passed  ] ""\e[m"
    fi
  elif "$@"; then
    echo -ne "\e[1m\e[32m""[  Passed  ] ""\e[m"
  else
    echo -ne "\e[1m\e[31m""[  Failed  ] ""\e[m"
  fi
  echo "$(basename "$0")|${_line_num}|assert $@"
}

function test::assert_equal {
  local _line_num=$(($1 - 23)) && shift
  local _val="$1" && shift
  if [ "${_val}" == "$(eval ${@})" ]; then
      echo -ne "\e[1m\e[32m""[  Passed  ] ""\e[m"
    else
      echo -ne "\e[1m\e[31m""[  Failed  ] ""\e[m"
    fi
    echo "$(basename "$0")|${_line_num}|assert_equal \"${_val}\" == \$($@)"
}

############################################################
# Init and Check, Do Not Modify
############################################################
util::check_bin sed
util::check_bin printf
util::check_bin echo
util::check_bin basename

# vim:ts=2:sw=2:et:ft=sh:
