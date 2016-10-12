#!/bin/bash
#===============================================================================
#      FILENAME: test_array.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, leoxiang@tencent.com
#       COMPANY: Tencent Co.Ltd
#      REVISION: 2012-07-06 by leoxiang
#===============================================================================

PATH="$(dirname $0)/../lbf:$PATH"
source lbf_init.sh

test::run

test::test_case test_array_op {
  test::assert array::init arr
  test::assert_equal 0 array::size arr
  test::assert array::add arr "one"
  test::assert array::add arr "two"
  test::assert array::add arr "three"
  test::assert array::add arr "four"
  test::assert array::add arr "five"
  test::assert array::add arr "six"

  test::assert_equal 6 array::size arr
  test::assert_equal "one"    array::get arr 0
  test::assert_equal "two"    array::get arr 1
  test::assert_equal "three"  array::get arr 2
  test::assert_equal "four"   array::get arr 3
  test::assert_equal "five"   array::get arr 4
  test::assert_equal "six"    array::get arr 5

  test::assert array::del arr "one" "three" "five"
  test::assert_equal 3 array::size arr
  test::assert_equal "two"    array::get arr 0
  test::assert_equal "four"   array::get arr 1
  test::assert_equal "six"    array::get arr 2

  test::assert array::del_by_idx arr 1 
  test::assert_equal 2 array::size arr
  test::assert_equal "two"    array::get arr 0
  test::assert_equal "six"    array::get arr 1

  test::assert array::free arr
}

test::test_case test_array_containing_space {
  test::assert array::init arr
  test::assert_equal 0 array::size arr

  test::assert array::add arr "1st node"
  test::assert array::add arr "2nd node"
  test::assert array::add arr "3rd node"

  test::assert_equal 3 array::size arr
  test::assert_equal "1st node" array::get arr 0
  test::assert_equal "2nd node" array::get arr 1
  test::assert_equal "3rd node" array::get arr 2

  test::assert array::del arr "1st node" "3rd node"
  test::assert_equal 1 array::size arr
  test::assert_equal "2nd node" array::get arr 0

  test::assert array::free arr
}

# vim:ts=2:sw=2:et:ft=sh:
