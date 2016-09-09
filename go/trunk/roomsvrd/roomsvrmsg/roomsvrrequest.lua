local skynet = require "skynet"
local filelog = require "filelog"
local msghelper = require "roomsvrhelper"
local msgproxy = require "msgproxy"
local base = require "base"
local configdao = require "configdao"

local filename = "RoomsvrRequest.lua"
local RoomsvrRequest = {}

function RoomsvrRequest.process(session, source, event, ...)
	local f = RoomsvrRequest[event] 
	if f == nil then
		filelog.sys_error(filename.." RoomsvrRequest.process invalid event:"..event)
		return
	end
	f(session, source, ...)
end

--[[
//请求创建朋友桌
message CreateFriendTableReq {
	optional Version version = 1;
	optional int32 room_type = 2;
	optional int32 game_type = 3;
	optional string name = 4;
	optional int32 game_time = 5;            --游戏限时单位s
	optional int32 retain_time = 6;          --朋友桌保留时间单位s
	optional int32 action_timeout = 7;       --玩家操作限时
	optional int32 action_timeout_count = 8; --玩家可操作超时次数
}

//响应创建朋友桌
message CreateFriendTableRes {
	optional int32 errcode = 1; //错误原因 0表示成功
	optional string errcodedes = 2; //错误描述
	optional string create_table_id = 3; //朋友桌索引号
}
]]

function RoomsvrRequest.createfriendtable(session, source, request)
	local responsemsg = {issucces = true,}
	if request.carry_chips == nil or request.big_blinds == nil or request.ante == nil or request.retain_time == nil or request.max_sitdown_playernum == nil or request.action_timeout == nil then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效请求！"
		base.skynet_retpack(responsemsg)
		filelog.sys_error("ROOMSVRD RoomsvrRequest.createfriendtable one invalid request param")
		return
	end

	if request.carry_chips == 0 or request.big_blinds == 0 or request.max_sitdown_playernum == 0 or request.retain_time == 0 or request.action_timeout == 0 then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效请求！"
		base.skynet_retpack(responsemsg)
		filelog.sys_error("ROOMSVRD RoomsvrRequest.createfriendtable two invalid request param")
		return
	end

	if request.carry_chips <= request.big_blinds or request.action_timeout < 10 or request.retain_time < 240 then
		responsemsg.issucces = false
		responsemsg.resultdes = "无效请求！"
		base.skynet_retpack(responsemsg)
		filelog.sys_error("ROOMSVRD RoomsvrRequest.createfriendtable three invalid request param")
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
		filelog.sys_error("ROOMSVRD RoomsvrRequest.createfriendtable create_friend_table failed")
    else
    	responsemsg.identify_code = identify_code
    end

    base.skynet_retpack(responsemsg)
end

return RoomsvrRequest