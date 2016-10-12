#!/bin/bash
#===============================================================================
#      FILENAME: test_io.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-07-05 by leoxiang
#===============================================================================

PATH="$(dirname $0)/../lbf:$PATH"
source lbf_init.sh

out_file="lbf_test_temp_file.tmp"

test::run

test::test_case redirect_func {
  rm -f $out_file
  test::assert io::redirect_output $out_file whoami
  test::assert_equal $USER cat $out_file

  rm -f $out_file
  test::assert_equal $USER io::copy_output $out_file whoami
  test::assert_equal $USER cat $out_file

  test::assert_equal "" io::no_output whoami
}

test::test_case test_color {
  test::assert io::no_output echo $(io::red    "this is red    color")
  test::assert io::no_output echo $(io::green  "this is green  color")
  test::assert io::no_output echo $(io::yellow "this is yellow color")
  test::assert io::no_output echo $(io::blue   "this is blue   color")
  test::assert io::no_output echo $(io::purple "this is purple color")
  test::assert io::no_output echo $(io::white  "this is white  color")
}

test::test_case test_log {
  rm -f $out_file
  test::assert io::log_info  $out_file "this is log test"
  test::assert io::log_warn  $out_file "this is log test"
  test::assert io::log_error $out_file "this is log test"
  test::assert io::log_info  $out_file $(io::yellow "this is log test, used with io::color")
  cat $out_file*
  rm -f $out_file*
}

# vim:ts=2:sw=2:et:ft=sh:
