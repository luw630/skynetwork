local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "roomsvrmsghelper"
local msgproxy = require "msgproxy"
local commonconst = require "common_const"
local base = require "base"
local configdao = require "configdao"

local filename = "roomrequestmsg.lua"
local RoomRequestMsg = {}

function RoomRequestMsg.process(session, source, event, ...)
	local f = RoomRequestMsg[event] 
	if f == nil then
		filelog.sys_error(filename.." RoomRequestMsg.process invalid event:"..event)
		base.skynet_retpack(nil)
		return nil
	end
	f(session, source, ...)
end

--[[
createfriendtable 46 {
	request {
		rid 0 : integer
		carry_chips 1 : integer #入桌携带筹码量
		big_blinds 2 : integer  #朋友桌的大盲
		ante 3 : integer        #朋友桌的前注		
		retain_time 4 : integer #朋友桌保留时间
		max_sitdown_playernum 5 : integer #朋友桌最多坐下人数
		action_timeout = 6: integer #朋友桌玩家出牌的倒计时时间		
		table_name 7: string     #桌子名称
	}

	response {
	    issucces 0 : boolean	 #true 成功  false 失败
		resultdes 1 : string	 #错误原因
		identify_code 2 : string #朋友桌随机码
	}
}
]]
function RoomRequestMsg.createfriendtable(session, source, request)
	local responsemsg = {issucces = true,}
	if request.carry_chips == nil or request.big_blinds == nil or request.ante == nil or request.retain_time == nil or request.max_sitdown_playernum == nil or request.action_timeout == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效请求！"
		base.skynet_retpack(responsemsg)
		filelog.sys_error("ROOMSVRD RoomRequestMsg.createfriendtable one invalid request param")
		return
	end

	if request.carry_chips == 0 or request.big_blinds == 0 or request.max_sitdown_playernum == 0 or request.retain_time == 0 or request.action_timeout == 0 then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效请求！"
		base.skynet_retpack(responsemsg)
		filelog.sys_error("ROOMSVRD RoomRequestMsg.createfriendtable two invalid request param")
		return
	end

	if request.carry_chips <= request.big_blinds or request.action_timeout < 10 or request.retain_time < 240 then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效请求！"
		base.skynet_retpack(responsemsg)
		filelog.sys_error("ROOMSVRD RoomRequestMsg.createfriendtable three invalid request param")
		return
	end 

	conf = {}
    conf.conf_version = 1
    conf.table_room_type = commonconst.ROOM_PRIVATE_TYPE     --桌子的房间类型
    conf.table_game_type = 1
    conf.small_blinds = math.ceil(request.big_blinds / 2)
    conf.min_player_num = 2  	 --最少开始游戏人数
    conf.max_player_num = request.max_sitdown_playernum  --桌子座位数
    conf.big_blinds = conf.small_blinds * 2
    if request.min_carrychips == nil then
    	conf.min_carry = request.carry_chips
   	else
    	conf.min_carry = request.min_carrychips
   	end

   	if request.max_carrychips == nil then
   		conf.max_carry = request.carry_chips
   	else
    	conf.max_carry = request.max_carrychips
   	end
    conf.game_draw_rate = 0      --房费占大盲的百分比
    conf.prop_price = 0
    --conf.table_name = request.table_name
    conf.table_name = "自建朋友桌"
    conf.calculate_win_expbase = 0
    conf.calculate_win_expratio = 0
    conf.calculate_lose_exp = 0
    conf.everyday_max_exp = 0     				 --每天玩家能获得的最大经验值
    conf.max_wait_num = 300       				 --最大旁观人数
    --conf.action_timeout = request.action_timeout*100 --玩家操作超时时间单位10ms
    conf.action_timeout = 2000 --玩家操作超时时间单位10ms
    conf.ante = request.ante             	     --前注
    conf.continuous_timeout = 2                  --连续超时判定次数
    conf.retain_time = request.retain_time
    conf.table_create_user = request.rid
    conf.table_create_user_rolename = request.rolename
    conf.table_create_user_logo = request.logo
    conf.is_control = request.is_control

    local result, identify_code = msghelper.create_friend_table(conf)
    if not result then
    	responsemsg.issucces = false
    	responsemsg.resultdes = "系统错误，创建朋友桌失败！"
		filelog.sys_error("ROOMSVRD RoomRequestMsg.createfriendtable create_friend_table failed")
    else
    	responsemsg.identify_code = identify_code
    end

    base.skynet_retpack(responsemsg)
end

--[[
#创建SNG朋友桌
createfriendsngtable 120 {
	request {
		version 0 : VersionType
		signup_cost 1 : integer				#报名费
		promotion_blinds_time 2 : integer	#升盲时间
		initial_chips 3 : integer  			#初始筹码
		player_num 4 : integer              #开桌人数
		is_control 5 : boolean              #是否控制带入
	}

	response {
        issucces 0 : boolean	 #true 成功  false 失败
		resultdes 1 : string	 #错误原因
		identify_code 2 : string #朋友桌随机码
	}
}
]]
function RoomRequestMsg.createfriendsngtable(session, source, request)
	local responsemsg = {issucces = true,}

	local friendsngcfg = configdao.get_business_conf(100, 1000, "friendsngcfg")
	if not friendsngcfg then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效请求！"
		base.skynet_retpack(responsemsg)
		filelog.sys_error("ROOMSVRD RoomRequestMsg.createfriendsngtable get_business_conf error")
		return
	end

	if request.signup_cost == nil
		or request.promotion_blinds_time == nil
		or request.initial_chips == nil
		or request.player_num == nil
		or request.is_control == nil
	then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效请求！"
		base.skynet_retpack(responsemsg)
		filelog.sys_error("ROOMSVRD RoomRequestMsg.createfriendsngtable one nil request param", request)
		return
	end

	if request.signup_cost < 0
		or request.player_num < 2 then
		--or friendsngcfg.PromotionBlindsTimeI[request.promotion_blinds_time] == nil
		--or friendsngcfg.InitialChipsI[request.initial_chips] == nil
		--or friendsngcfg.MatchRewards[request.player_num] == nil
	--then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效请求！"
		base.skynet_retpack(responsemsg)
		filelog.sys_error("ROOMSVRD RoomRequestMsg.createfriendsngtable one invalid request param", request)
		return
	end

	conf = {}
    conf.conf_version = 1
    conf.table_room_type = commonconst.ROOM_FRIEND_SNG_TYPE     --桌子的房间类型
    conf.table_game_type = 1

    conf.signup_cost = request.signup_cost
    conf.promotion_blinds_time = request.promotion_blinds_time
    conf.initial_chips = request.initial_chips
    conf.player_num = request.player_num
    conf.is_control = request.is_control

    -- 服务费
    conf.service_fee = math.floor(request.signup_cost * configdao.get_common_conf("friendsng_fee"))
    if conf.player_num == 2 then
        conf.service_fee = 0
    end

    conf.table_create_user = request.rid
    conf.table_create_user_rolename = request.rolename
    conf.table_create_user_logo = request.logo

    conf.action_timeout = 20*100 --玩家操作超时时间单位10ms
    conf.continuous_timeout = 2  --连续超时判定次数
    conf.max_wait_num = 300		 --旁观人数
    conf.retain_time = 2*60*60   --报名超时时间2小时
    conf.min_player_num = 2
    conf.max_player_num = request.player_num

    conf.small_blinds = friendsngcfg.PromotionBlinds[1][1]
    conf.big_blinds = friendsngcfg.PromotionBlinds[1][2]

    conf.game_draw_rate = 0
    conf.min_carry = 0

    conf.calculate_win_expbase = 0
    conf.calculate_win_expratio = 0
    conf.calculate_lose_exp = 0
    conf.everyday_max_exp = 0

    local result, identify_code = msghelper.create_friend_sng_table(conf)
    if not result then
    	responsemsg.issucces = false
    	responsemsg.resultdes = "系统错误，创建朋友桌失败！"
		filelog.sys_error("ROOMSVRD RoomRequestMsg.createfriendsngtable create_friend_sng_table failed")
    else
    	responsemsg.identify_code = identify_code
    end

    base.skynet_retpack(responsemsg)
end

function RoomRequestMsg.gmcommand(session, source, cmd, ...)
	if cmd == nil then
		base.skynet_retpack(false)
		return
	end

	if cmd == "reload" then
		msghelper.reload_config()
		base.skynet_retpack(true)
		return		
	end

	if cmd=="table_info" then
		local tablelist = msghelper.get_tablelist()
		local table_id = ...

		if tablelist[table_id] == nil then
			base.skynet_retpack(false)
			return
		end
		
		local table_info = skynet.call(tablelist[table_id].table, "lua",  "request", "get_table_info")
		base.skynet_retpack(table_info)
		return
	end

	base.skynet_retpack(false)
	return
end

return RoomRequestMsg