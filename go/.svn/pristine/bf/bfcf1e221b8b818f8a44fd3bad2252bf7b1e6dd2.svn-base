#!/bin/bash
#===============================================================================
#      FILENAME: publish.sh
#
#   DESCRIPTION: ---
#         NOTES: ---
#        AUTHOR: leoxiang, xiangkun@ximigame.com
#       COMPANY: XiMi Co.Ltd
#      REVISION: 2014-12-31 by leoxiang
#===============================================================================

function usage
{
  echo "./publish [name]"
  exit
}

PATH="$(dirname $0)/lbf/lbf:$PATH"
source lbf_init.sh

[ "$1" = "" ] && usage

echo "please select which to pack: "
echo "1)  hallsvrd"
echo "2)  gamesvrd"
echo "3)  tablesvrd"
echo "4)  shopsvrd"
echo "5)  gmsvrd"
echo "6)  gtplsvrd"
echo "7)  httpsvrd"
echo "8)  thirdsvrd"
echo "9)  xiproxysvrd"
echo "10) authsvrd"
echo "11) auth_dbsvrd"
echo "12) logsvrd"
echo "13) redis_svrd"
echo "14) base_dbsvrd"
echo "15) matchsvrd"
echo "16) matchroomsvrd"
echo "17) tcpsvrd"
echo "18) *scripts"
echo "19) *configs"
echo "20) lib"
echo "21) all"
echo "22) friend"
echo "23) gm_tool"
echo "24) eventsvrd"
read -p "please select which to pack: " var_select_list

var_pack_list=""

for _var_select in ${var_select_list}; do
  case ${_var_select} in 
    1)  var_pack_list+=" ./svr/hallsvrd/bin/hallsvrd" 
        ;;
    2)  var_pack_list+=" ./svr/gamesvrd/bin/gamesvrd" 
        ;;
    3)  var_pack_list+=" ./svr/tablesvrd/bin/tablesvrd" 
        ;;
    4)  var_pack_list+=" ./svr/shopsvrd/bin/shopsvrd" 
        ;;
    5)  var_pack_list+=" ./svr/gmsvrd/bin/gmsvrd"
        ;;
    6)  #var_pack_list+=" ./svr/gtplsvrd/deploy"
        var_pack_list+=" ./svr/gtplsvrd/bin/gtplsvrd"
        ;;
    7)  var_pack_list+=" ./svr/httpsvrd/bin/httpsvrd"
        ;;
    8)  var_pack_list+=" ./svr/thirdsvrd/bin/thirdsvrd"
        ;;
    9)  var_pack_list+=" ./svr/proxysvrd/bin/proxysvrd"
        var_pack_list+=" ./svr/proxysvrd/deploy/hash2game.map"
        ;;
    10) var_pack_list+=" ./svr/authsvrd/bin/authsvrd"
        ;;
    11) var_pack_list+=" ./svr/auth_dbsvrd/bin/auth_dbsvrd"
        #var_pack_list+=" ./svr/auth_dbsvrd/db/*.sh"
        #var_pack_list+=" ./svr/auth_dbsvrd/db/*.sql"
        #var_pack_list+=" ./svr/auth_dbsvrd/db/*.cpp"
        ;;
    12) var_pack_list+=" ./svr/logsvrd/bin/logsvrd"
        ;;
    13) var_pack_list+=" ./svr/redis_dbsvrd/bin/redis_dbsvrd"
        ;;
    14) var_pack_list+=" ./svr/base_dbsvrd/bin/base_dbsvrd"
	var_pack_list+=" ./svr/base_dbsvrd/texasdb/altertable.sql"
	var_pack_list+=" ./svr/base_dbsvrd/texasdb/altertable.sh"
        ;;
    15) var_pack_list+=" ./svr/matchsvrd/bin/matchsvrd"
        ;;
    16) var_pack_list+=" ./svr/matchroomsvrd/bin/matchroomsvrd"
        ;;
    17) var_pack_list+=" ./svr/tcpsvrd/bin/tcpsvrd"
        #var_pack_list+=" ./svr/tcpsvrd/deploy/tcpsvrd_gmsvrd.cfg"
        ;;
    18) #var_pack_list+=" ./lbf"
        #var_pack_list+=" ./server.sh" 
        ;;
    19) 
        #var_pack_list+=" ./svr/config/toplist" 
        #var_pack_list+=" ./svr/config/luascripts/channels.lua"
        #var_pack_list+=" ./svr/logsvrd/deploy/logsvrdcommon.cfg" 
        #var_pack_list+=" ./svr/config/resource/marquee.phone.CFG" 
        #var_pack_list+=" ./svr/config/resource/marquee.CFG" 
        #var_pack_list+=" ./svr/config/resource/system_message.CFG" 
        #var_pack_list+=" ./svr/config/resource/system_message.xiaomiph.CFG" 
        #var_pack_list+=" ./svr/config/resource/shop.CFG"
        #var_pack_list+=" ./svr/config/resource/shop.xiaomiph.CFG"
        #var_pack_list+=" ./svr/config/resource/shop.shiboyun.CFG"
        #var_pack_list+=" ./svr/config/resource/item_pkg.CFG"
        #var_pack_list+=" ./svr/config/resource/cycle_template_list.CFG"
        #var_pack_list+=" ./svr/config/resource/client_version.CFG"
        #var_pack_list+=" ./svr/config/resource/continue_login.CFG"
        #var_pack_list+=" ./svr/config/resource/novicepackage.CFG"
        #var_pack_list+=" ./svr/config/resource/turntable.CFG"
        #var_pack_list+=" ./svr/config/resource/turntable.xiaomi.CFG"
        #var_pack_list+=" ./svr/config/resource/turntable.shiboyun.CFG"
        #var_pack_list+=" ./svr/config/resource/turntable.lianxiang.CFG"
        #var_pack_list+=" ./svr/config/resource/turntable.xiaomi.phone.CFG"
        #var_pack_list+=" ./svr/config/resource/activities.CFG"
        #var_pack_list+=" ./svr/config/resource/activities.xiaomi.phone.CFG"
        #var_pack_list+=" ./svr/config/resource/award_template_list.CFG"
        #var_pack_list+=" ./svr/config/resource/match_room_list.CFG"
        #var_pack_list+=" ./svr/config/resource/prop.CFG"
        #var_pack_list+=" ./svr/config/resource/blind_template_list.CFG"
        #var_pack_list+=" ./svr/config/resource/play_count_activity.CFG"
        #var_pack_list+=" ./svr/config/resource/play_count_activity2.CFG"
        #var_pack_list+=" ./svr/config/gamesvrd/gamesvrd.CFG"
        #var_pack_list+=" ./svr/config/gamesvrd/private_room.CFG"
        #var_pack_list+=" ./svr/config/resource/common_activity_switch.CFG"
        #var_pack_list+=" ./svr/config/resource/novice_award_pkg.CFG"
        #var_pack_list+=" ./svr/config/resource/novice_award_pkg_2.CFG"
        #var_pack_list+=" ./svr/config/resource/friend.CFG"
        #var_pack_list+=" ./svr/config/resource/client_channel_type_list.CFG"
        #var_pack_list+=" ./svr/config/gamesvrd/robot.CFG"
        #var_pack_list+=" ./svr/config/resource/olduser_task_list.CFG"
        #var_pack_list+=" ./svr/config/resource/newuser_task_list.CFG"
        #var_pack_list+=" ./svr/config/resource/main_task_list.CFG"
        #var_pack_list+=" ./svr/config/resource/f_code.CFG"
        #var_pack_list+=" ./svr/base_dbsvrd/texasdb/gift_pack.SH"
        #var_pack_list+=" ./svr/config/resource/phone_notice.CFG"
        #var_pack_list+=" ./svr/config/resource/free_award.CFG"
        #var_pack_list+=" ./svr/config/resource/magic_expression_pkg.CFG"
        #var_pack_list+=" ./svr/config/resource/time_limit_card.CFG"
        #var_pack_list+=" ./svr/config/resource/tip_dealer_consume.CFG"
        #var_pack_list+=" ./svr/config/resource/tip_dealer_dialog_content.CFG"
        #var_pack_list+=" ./svr/config/resource/tip_dealer_trigger_odds.CFG"
        #var_pack_list+=" ./svr/config/resource/play_time_activity.CFG"
        #var_pack_list+=" ./svr/config/resource/duanwu.CFG"
        #var_pack_list+=" ./svr/config/resource/interaction.CFG"
        #var_pack_list+=" ./svr/config/resource/bankruptcy_protection.CFG"
        #var_pack_list+=" ./svr/config/resource/quick_start.CFG"
        #var_pack_list+=" ./svr/config/resource/slot_machine.CFG"
        #var_pack_list+=" ./svr/config/resource/slot_machine_activity.CFG"
        #var_pack_list+=" ./svr/config/resource/specific_point_activity.CFG"
        #var_pack_list+=" ./svr/config/dirty/dirty_chn.CFG"
        #var_pack_list+=" ./svr/config/resource/trainee.CFG"
        #var_pack_list+=" ./svr/config/resource/vip_right.CFG"
        #var_pack_list+=" ./svr/config/resource/explevel.CFG"
        #var_pack_list+=" ./svr/config/resource/continue_login.xiaomiph.CFG"
        #var_pack_list+=" ./svr/config/resource/achievement.CFG"
        #var_pack_list+=" ./svr/config/resource/achievement_task_list.CFG"
        #var_pack_list+=" ./svr/config/resource/qixi_festival.CFG"
        #var_pack_list+=" ./svr/config/resource/award_exchange.CFG"
        #var_pack_list+=" ./svr/config/resource/record.CFG"
        #var_pack_list+=" ./svr/config/resource/bet_3cards.CFG"
        #var_pack_list+=" ./svr/config/resource/collect_card_activity.CFG"
        #var_pack_list+=" ./svr/config/resource/newhall_activities.CFG"
        #var_pack_list+=" ./svr/config/resource/newhall_notice_message.CFG"
        ;;
    20) var_pack_list+=" ./svr/lib"
        ;;
    21) var_pack_list+=" ./lbf"
        var_pack_list+=" ./server.sh" 
        var_pack_list+=" ./svr/lib"
        var_pack_list+=" ./svr/config/resource" 
        var_pack_list+=" ./svr/config/gamesvrd" 
        var_pack_list+=" ./svr/config/toplist" 
        var_pack_list+=" ./svr/config/dirty" 
        var_pack_list+=" ./svr/config/luascripts"
        var_pack_list+=" ./svr/hallsvrd/bin/hallsvrd"
        var_pack_list+=" ./svr/hallsvrd/deploy"
        var_pack_list+=" ./svr/gamesvrd/bin/gamesvrd"
        var_pack_list+=" ./svr/gamesvrd/deploy"
        var_pack_list+=" ./svr/tablesvrd/bin/tablesvrd"
        var_pack_list+=" ./svr/tablesvrd/deploy"
        var_pack_list+=" ./svr/shopsvrd/bin/shopsvrd"
        var_pack_list+=" ./svr/shopsvrd/deploy"
        var_pack_list+=" ./svr/gmsvrd/bin/gmsvrd"
        var_pack_list+=" ./svr/gmsvrd/deploy"
        var_pack_list+=" ./svr/gtplsvrd/bin/gtplsvrd"
        var_pack_list+=" ./svr/gtplsvrd/deploy"
        var_pack_list+=" ./svr/httpsvrd/bin/httpsvrd"
        var_pack_list+=" ./svr/httpsvrd/deploy"
        var_pack_list+=" ./svr/thirdsvrd/bin/thirdsvrd"
        var_pack_list+=" ./svr/thirdsvrd/deploy"
        var_pack_list+=" ./svr/xiproxysvrd/bin/xiproxysvrd"
        var_pack_list+=" ./svr/xiproxysvrd/deploy"
        var_pack_list+=" ./svr/authsvrd/bin/authsvrd"
        var_pack_list+=" ./svr/authsvrd/deploy"
        var_pack_list+=" ./svr/auth_dbsvrd/bin/auth_dbsvrd"
        var_pack_list+=" ./svr/auth_dbsvrd/deploy"
        var_pack_list+=" ./svr/auth_dbsvrd/db"
        var_pack_list+=" ./svr/logsvrd/bin/logsvrd"
        var_pack_list+=" ./svr/logsvrd/deploy"
        var_pack_list+=" ./svr/redis_dbsvrd/bin/redis_dbsvrd"
        var_pack_list+=" ./svr/redis_dbsvrd/deploy"
        var_pack_list+=" ./svr/base_dbsvrd/bin/base_dbsvrd"
        var_pack_list+=" ./svr/base_dbsvrd/deploy"
        var_pack_list+=" ./svr/base_dbsvrd/texasdb"
        var_pack_list+=" ./svr/matchsvrd/bin/matchsvrd"
        var_pack_list+=" ./svr/matchsvrd/deploy"
        var_pack_list+=" ./svr/matchroomsvrd/bin/matchroomsvrd"
        var_pack_list+=" ./svr/matchroomsvrd/deploy"
        var_pack_list+=" ./svr/tcpsvrd/bin/tcpsvrd"
        var_pack_list+=" ./svr/tcpsvrd/bin/start_tcpsvrd.sh"
        var_pack_list+=" ./svr/tcpsvrd/deploy"
        var_pack_list+=" ./svr/friendsvrd/deploy"
        var_pack_list+=" ./svr/friendsvrd/bin"
        ;;
    22) var_pack_list+=" ./svr/friendsvrd/bin/friendsvrd"
		;;

    23) var_pack_list+=" ./svr/gmsvrd/issue_reward/poker_gm_tool"
        var_pack_list+=" ./svr/gmsvrd/issue_reward/poker_gm_tool_issue_reward"
        var_pack_list+=" ./svr/gmsvrd/issue_reward/auto_reward.sh"
        var_pack_list+=" ./svr/gmsvrd/issue_reward/texas.cron"
        var_pack_list+=" ./svr/gmsvrd/issue_reward/gm.cfg"
        var_pack_list+=" ./svr/redis_dbsvrd/tool/poker_data_stats"

        ;;
    24) var_pack_list+=" ./svr/eventsvrd/bin/eventsvrd"
        #var_pack_list+=" ./svr/eventsvrd/deploy"
	;;
    *)  echo "unknown tpye ${_var_select}"; exit 0;;
  esac
done

echo "================="
echo "delete privious files"
var_dir="../package"
svn up  ${var_dir} --accept theirs-full
svn revert ${var_dir} -R
svn del ${var_dir}/* --force

echo "================="
echo "begin pack"
var_file="${var_dir}/texas_$1_$(date '+%Y%m%d%H%M%S').zip"
zip -r ${var_file} ${var_pack_list} --exclude \*.svn\*

echo "================="
echo "calc md5"
echo http://insvn.ximigame.net/svn/serversvn/codebase/games/texas/package/$(basename ${var_file})
md5sum ${var_file}

echo "================="
echo "upload svn"
svn add ${var_file}
svn ci  ${var_dir} -m "texas package ${var_file}"

# vim:ts=2:sw=2:et:
