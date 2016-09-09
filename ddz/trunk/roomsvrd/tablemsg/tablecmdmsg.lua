local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "tablemsghelper"
local timer = require "timer"
local filename = "tablecmdmsg.lua"
local msgproxy = require "msgproxy"
local commonconst = require "common_const"
local timetool = require "timetool"
local base = require "base"
require "const.enum"
local CMD = {}

function CMD.process(session, source, event, ...)
	local f = CMD[event] 
	if f == nil then
		filelog.sys_error(filename.." CMD.process invalid event:"..event)
		return nil
	end
	f(...)	 
end

function CMD.start(conf, roomsvr, tableid)
	if conf == nil or roomsvr == nil or tableid == nil then
		filelog.sys_error(filename.."conf == nil or roomsvr == nil or tableid == nil")
		skynet.ret(skynet.pack(false))
		return
	end

	local table_data = msghelper.get_tabledata()
	table_data.table_id = tableid
	table_data.sitdown_player_num = 0

	msghelper.init_tabledata_conf(conf)
	
     --创建座位
    local count = 1
    while count <= 9 do
    	local seat = {	
    			index = count,
    			rid = 0,
				state = commonconst.PLAYER_STATE_NO_PLAYER, 		--改坐位玩家状态
				gatesvr_id = "",
				agent_address = nil,
				outtable_chips = 0, --记录桌外筹码
				carry_chips = 0,    --坐下时携带进桌的筹码
				chips = 0,          --玩家在牌桌内的筹码
				bet_chips = 0,      --玩家已下筹码
				is_tuoguan = false, --玩家是否托管
				sng_rank = 0,       --玩家SNG的排名
				playerinfo = {
					rolename="",
					logo="",
					sex=false,
				},
				cards = {},
				card_form = 0,   --牌型
				form_cards = {}, --牌型对应的牌
				bunko = 0,
				onegame_winchips = 0,
				is_robot = false,

				bet_num = 0,
				raise_num = 0,
				call_num = 0,
				threebet_num = 0,
				steal_num = 0,
				continuebet_num = 0,
				current_round = 0,
				currentround_betnum = 0,
				lastround_betnum = 0,
				last_round = 0,
				othercontinuebet_num = 0,
				foldtocontinuebet_num = 0,
				preflopraise_num = 0,
				steal_num = 0,
				othersteal_num = 0,
				foldsteal_num = 0,
				is_maxcardform = false, 
		}
		table_data.tableseats[count] = seat
		count = count + 1
    end

    msghelper.set_table_conf(conf)
    msghelper.set_roomsvr(roomsvr)

    if conf.table_room_type == commonconst.ROOM_SNG_TYPE then
    	--SNG
    	msghelper.init_game("snggame")
    elseif conf.table_room_type == commonconst.ROOM_PRIVATE_TYPE then
    	--朋友桌
    	msghelper.init_game("friendgame")
    	msghelper.set_tablestate(commonconst.TABLE_STATE_WAIT_GAME_START)
    	msghelper.add_tablestateinfo(ETableStateinfoType.TABLE_STATEINFO_CREATE, conf.table_create_user, 0, timetool.get_time(), conf.table_create_user_rolename)
    elseif conf.table_room_type == commonconst.ROOM_FRIEND_SNG_TYPE then
    	--朋友SNG桌
    	msghelper.init_game("friendsnggame")
    	msghelper.set_tablestate(commonconst.TABLE_STATE_WAIT_GAME_START)
    	msghelper.add_tablestateinfo(ETableStateinfoType.TABLE_STATEINFO_CREATE, conf.table_create_user, 0, timetool.get_time(), conf.table_create_user_rolename)
    else 
    	--积分赛
    	--(conf.table_room_type == commonconst.ROOM_PRIMARY_TYPE or conf.table_room_type == commonconst.ROOM_MIDDLE_TYPE or conf.table_room_type == commonconst.ROOM_ADVANCE_TYPE or conf.table_room_type == commonconst.ROOM_MASTER_TYPE) then 
    	msghelper.init_game("game")
    end

    if conf.table_room_type == commonconst.ROOM_PRIVATE_TYPE then
    	--朋友桌结束时间
    	table_data.deletetable_timer_id = timer.settimer(conf.retain_time*100, "deletetable")
    end
    if conf.table_room_type == commonconst.ROOM_FRIEND_SNG_TYPE then
    	--朋友桌SNG结束时间
    	table_data.cancelmatch_timer_id = timer.settimer(conf.retain_time*100, "cancelmatch")
    end

    --上报状态
    msghelper.report_tablestate()
	
	skynet.ret(skynet.pack(true))

	--尝试设置拉取机器人的ID
	skynet.fork(function()
		skynet.sleep(4000)
		if msghelper.is_canapplyrobot() and conf.robot_type == ERobotType.ROBOT_TYPE_ACTIVE then
			local applyrobottimermsg = {table_id=tableid, robot_num=1}
			table_data.applyrobot_timer_id = timer.settimer(base.get_random(table_data.robot_enter_mintime, table_data.robot_enter_maxtime) * 100, "applyrobot", applyrobottimermsg)
		end
	end)
end

function CMD.reload(conf)
	if conf == nil then
		filelog.sys_error(filename.."conf == nil")
	end 
	local table_conf = msghelper.get_table_conf()

	if conf.conf_version <= table_conf.conf_version then
		--版本没有更新不需要更新配置
		return
	end
	local table_data = msghelper.get_tabledata()

	if table_conf.robot_type ~= ERobotType.ROBOT_TYPE_ACTIVE and conf.robot_type == ERobotType.ROBOT_TYPE_ACTIVE then
		skynet.fork(function()
			skynet.sleep(4000)
			if msghelper.is_canapplyrobot() and conf.robot_type == ERobotType.ROBOT_TYPE_ACTIVE then
				local applyrobottimermsg = {table_id=table_data.table_id, robot_num=1}
				table_data.applyrobot_timer_id = timer.settimer(base.get_random(table_data.robot_enter_mintime, table_data.robot_enter_maxtime) * 100, "applyrobot", applyrobottimermsg)
			end
		end)
	end

	msghelper.set_table_conf(conf)
	--判断当前状态是否需要立即更新配置
	if msghelper.is_gameend() then
		msghelper.init_tabledata_conf(conf)
		--上报状态
    	msghelper.report_tablestate()
	else
		msghelper.set_isupdateconf(true)
	end
end

function CMD.delete(...)
	--上报桌子管理器房间被删除
	local table_data = msghelper.get_tabledata()
	msgproxy.send_broadcastmsgto_tablesvrd("tabledelete", msghelper.get_roomsvr(), table_data.table_id)
	
	--检查桌子当前是否能够删除
	if not msghelper.is_noplayer() and not table_data.isdelete then
		--当桌子为空时再删除桌子
		table_data.isdelete = true
	end

	if not msghelper.is_gameend() then
		return
	end

	--踢出座位上的玩家
	msghelper.kickallplayer()

	msgproxy.send_broadcastmsgto_tablesvrd("tabledelete", msghelper.get_roomsvr(), table_data.table_id)

	--通知roomsvrd删除table
	skynet.send(msghelper.get_roomsvr(), "lua", "cmd", "delete_table", table_data.table_id)
	
	--给锁定筹码玩家退还筹码
	msghelper.refund_fixedchips()
	
	--保存战绩
	msghelper.save_tablesrecord()
	
	--删除桌子前清除桌子的状态
	msghelper.clear_table()

	--延迟释放桌子
	skynet.sleep(10)
	skynet.exit()
end

return CMD