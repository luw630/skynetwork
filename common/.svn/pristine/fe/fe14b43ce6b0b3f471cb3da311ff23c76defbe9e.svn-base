#!/bin/bash
#===============================================================================
#      FILENAME: test_util.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-07-04 by leoxiang
#===============================================================================

PATH="$(dirname $0)/../lbf:$PATH"
source lbf_init.sh

test::run

test::test_case test_util {
  test::assert util::is_empty $VARIABLE_WHICH_IS_NOT_EXIST
  test::assert ! util::is_empty $HOME

  test::assert util::check_bin ls
  test::assert util::check_bin read
  test::assert ! util::check_bin non_exist_command $>/dev/null
}

test::test_case test_num_convert {
  test::assert_equal ff util::to_hex 255
  test::assert_equal ff util::to_hex 0xff
  test::assert_equal ff util::to_hex 0377

  test::assert_equal 255 util::to_dec 255
  test::assert_equal 255 util::to_dec 0xff
  test::assert_equal 255 util::to_dec 0377

  test::assert_equal 377 util::to_oct 255
  test::assert_equal 377 util::to_oct 0xff
  test::assert_equal 377 util::to_oct 0377
}

# vim:ts=2:sw=2:et:ft=sh:
