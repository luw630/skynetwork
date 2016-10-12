#!/bin/bash
#===============================================================================
#      FILENAME: test_path.sh
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

test::test_case test_path_func {
  test::assert_equal "basename" path::basename "/dirname/basename"
  test::assert_equal "basename" path::basename "/dirname/basename/"
  test::assert_equal "basename" path::basename "/basename"
  test::assert_equal "/" path::basename "/"
  test::assert_equal "." path::basename "."

  test::assert_equal "/dirname" path::dirname "/dirname/basename"
  test::assert_equal "/" path::dirname "/dirname"
  test::assert_equal "/" path::dirname "/"
  test::assert_equal "." path::dirname "basename"

  test::assert_equal "/usr" path::absname "/usr/local/.."

  test::assert_equal "suffix" path::suffix "/dirname/basename.suffix"
  test::assert_equal "suffix" path::suffix "basename.suffix"
  test::assert_equal "suffix" path::suffix ".suffix"
  test::assert_equal "suffix" path::suffix "suffix"
}

test::test_case test_bool_op {
  test::assert path::is_exist "/"
  test::assert path::is_exist "/bin/ls"

  test::assert path::is_dir  "/"
  test::assert path::is_file "/bin/ls"

  if [ $USER == "root" ]; then
    test::assert path::is_writable "/"
    test::assert path::is_writable "/bin"
  else
    test::assert ! path::is_writable "/"
    test::assert ! path::is_writable "/bin"
  fi

  test::assert path::is_readable "/"
  test::assert path::is_readable "/bin/ls"

  test::assert path::is_executable "/"
  test::assert path::is_executable "/bin/ls"
}

test::test_case test_cur_path {
  test::assert_equal "$(dirname $0)" path::cur_dirname
}

# vim:ts=2:sw=2:et:ft=sh:
